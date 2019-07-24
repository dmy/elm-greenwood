use crate::db;
use crate::db::models::Package;
use crate::elm;
use crate::release::Release;
use chrono::{Datelike, Local, TimeZone, Utc};
use rss::*;
use std::collections::HashMap;

pub fn all(query: HashMap<String, String>, release: &Release) -> String {
    let conn = db::connect();
    let packages = db::last_packages(&conn, &query, release);
    let items: Vec<Item> = packages.iter().map(item).filter_map(Result::ok).collect();
    let title = channel_title(&query, release);
    let last_timestamp = packages
        .iter()
        .map(|item| item.timestamp)
        .max()
        .unwrap_or(Utc::now().timestamp());

    let channel = ChannelBuilder::default()
        .title(&title)
        .link("https://elm-greenwood.com")
        .description(format!("{} from elm-greenwood.com", &title))
        .image(channel_image())
        .webmaster("admin@elm-greenwood.com".to_string())
        .copyright(channel_copyright())
        .pub_date(Utc.timestamp(last_timestamp, 0).to_rfc2822())
        .language("en-us".to_string())
        .categories(channel_categories(release))
        .items(items)
        .build()
        .unwrap()
        .to_string();

    format!(
        "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\" ?>\n{}",
        channel
    )
}

fn channel_title(query: &HashMap<String, String>, release: &Release) -> String {
    let release_type = match release {
        Release::Any => "releases",
        Release::Last => "last release",
        Release::First => "first release",
        Release::Major => "major releases",
        Release::Minor => "minor releases",
        Release::Patch => "patch releases",
    };
    let pkgs =
        query
        .iter()
        .fold(vec![], |mut pkgs, (author,names)| {
            pkgs.push(format!("{}/{}", author, str::replace(names, " ", "+")));
            pkgs
        });

    if pkgs.is_empty() {
        format!("Elm packages {}", release_type)
    } else {
        format!("Elm package {} of {}", &release_type, pkgs.join(", "))
    }
}

fn channel_image() -> Option<Image> {
    ImageBuilder::default()
        .title("Elm logo")
        .link("https://elm-greenwood.com")
        .url("https://github.com/elm.png")
        .build()
        .ok()
}

fn channel_copyright() -> String {
    format!("Elm Greenwood © {}", Local::now().year())
}

fn channel_categories(release: &Release) -> Vec<Category> {
    let location = match release {
        Release::Any => "Elm/Packages/Releases",
        Release::Last => "Elm/Packages/Last Releases",
        Release::First => "Elm/Packages/First Releases",
        Release::Major => "Elm/Packages/Major Releases",
        Release::Minor => "Elm/Packages/Minor Releases",
        Release::Patch => "Elm/Packages/Patch Releases",
    };
    vec![category(elm::PACKAGES_URL, location)]
}

fn item(package: &Package) -> Result<Item, String> {
    ItemBuilder::default()
        .title(item_title(package))
        .link(item_link(package))
        .guid(item_guid(package))
        .pub_date(item_pub_date(package))
        .description(package.summary.to_string())
        .comments(item_comments(package))
        .categories(item_categories(package))
        .build()
}

fn item_title(package: &Package) -> String {
    format!(
        "{}/{} {}.{}.{}",
        package.author, package.name, package.major, package.minor, package.patch
    )
}

fn item_link(package: &Package) -> String {
    format!(
        "{}/packages/{}/{}/{}.{}.{}/",
        elm::PACKAGES_URL,
        package.author,
        package.name,
        package.major,
        package.minor,
        package.patch
    )
}

fn item_guid(package: &Package) -> Option<Guid> {
    GuidBuilder::default()
        .permalink(true)
        .value(item_link(package))
        .build()
        .ok()
}

fn item_pub_date(package: &Package) -> String {
    Utc.timestamp(package.timestamp, 0).to_rfc2822()
}

fn item_comments(package: &Package) -> String {
    format!(
        "https://github.com/{}/{}/tree/{}.{}.{}",
        package.author, package.name, package.major, package.minor, package.patch
    )
}

fn item_categories(package: &Package) -> Vec<Category> {
    let deps: HashMap<String, String> =
        serde_json::from_str(&package.dependencies).unwrap_or(HashMap::new());

    let mut categories: Vec<Category> = deps
        .into_iter()
        .map(|(pkg, constraint)| dependency(&pkg, &constraint))
        .collect();
    categories.push(category("elm", &format!("elm {}", &package.elm_version)));
    categories.push(category("license", &package.license));
    categories
}

fn dependency(pkg: &str, constraint: &str) -> Category {
    category("dependency", &format!("{} {}", pkg, constraint))
}

fn category<S>(domain: S, location: S) -> Category
where
    S: Into<String>,
{
    let mut category = Category::default();
    category.set_domain(domain.into());
    category.set_name(cdata(location));
    category
}

fn cdata<S>(data: S) -> String
where
    S: Into<String>,
{
    let string = data.into();
    if string.contains("<") {
        format!("<![CDATA[{}]]>", string)
    } else {
        string
    }
}
