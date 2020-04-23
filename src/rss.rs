use crate::db;
use crate::db::models::Package;
use crate::elm;
use crate::release::Release;
use chrono::{Datelike, Local, TimeZone, Utc};
use rss::*;
use std::collections::HashMap;

pub fn all(user_agent: String, query: HashMap<String, String>, release: &Release) -> String {
    let conn = db::connect();
    let title = channel_title(&query, release);
    let packages = db::last_packages(&conn, query, release, 42);
    let items: Vec<Item> = packages
        .iter()
        .map(|pkg| item(&user_agent, pkg))
        .filter_map(Result::ok)
        .collect();
    let last_timestamp = packages
        .iter()
        .map(|item| item.timestamp)
        .max()
        .unwrap_or(Utc::now().timestamp());

    let mut namespaces = HashMap::new();
    namespaces.insert(
        "content".to_string(),
        "http://purl.org/rss/1.0/modules/content/".to_string(),
    );
    let channel = ChannelBuilder::default()
        .namespaces(namespaces)
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
    let pkgs = query.iter().fold(vec![], |mut pkgs, (author, names)| {
        if author != "_search" {
            pkgs.push(format!("{}/{}", author, str::replace(names, " ", "+")));
        }
        pkgs
    });

    match (pkgs.is_empty(), query.get("_search")) {
        (true, None) => format!("Elm packages {}", &release_type),
        (true, Some(pattern)) => format!("Elm packages {} matching {}", &release_type, pattern),
        (false, None) => format!("Elm packages {} of {}", &release_type, pkgs.join(", ")),
        (false, Some(pattern)) => format!(
            "Elm packages {} of {} or matching {}",
            &release_type,
            pkgs.join(", "),
            pattern
        ),
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

fn item(user_agent: &String, package: &Package) -> Result<Item, String> {
    ItemBuilder::default()
        .title(item_title(package))
        .link(item_link(package))
        .guid(item_guid(package))
        .pub_date(item_pub_date(package))
        .description(item_description(user_agent, package))
        .comments(item_comments(package))
        .categories(item_categories(package))
        .content(item_content(package))
        .build()
}

fn item_title(package: &Package) -> String {
    format!(
        "{author}/{name} {major}.{minor}.{patch}{emoji}",
        author = package.author,
        name = package.name,
        major = package.major,
        minor = package.minor,
        patch = package.patch,
        emoji = if is_new_package(package) { "✨" } else { "" }
    )
}

fn is_new_package(package: &Package) -> bool {
    if package.major == 1 && package.minor == 0 && package.patch == 0 {
        return true;
    } else {
        return false;
    }
}

fn item_link(package: &Package) -> String {
    format!(
        "https://package.elm-lang.org/packages/{author}/{name}/{major}.{minor}.{patch}/",
        author = package.author,
        name = package.name,
        major = package.major,
        minor = package.minor,
        patch = package.patch,
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

fn item_description(user_agent: &String, package: &Package) -> String {
    if is_slack(user_agent) {
        format!(
            "{elm_version}<br/><br/>{summary}",
            elm_version = escape(user_agent, elm_version(package)),
            summary = escape(user_agent, &package.summary)
        )
    } else {
        escape(user_agent, &package.summary)
    }
}

fn is_slack(user_agent: &String) -> bool {
    if user_agent.contains("Slackbot") {
        return true;
    } else {
        return false;
    }
}

fn elm_version(package: &Package) -> String {
    let splitter = |c| c == '.' || c == ' ';
    let fields: Vec<&str> = package.elm_version.split(splitter).collect();
    if let [maj1, min1, "0", "<=", "v", "<", maj2, min2, "0"] = &fields[..] {
        if let (Some(lower), Some(upper)) = (min1.parse::<i32>().ok(), min2.parse::<i32>().ok()) {
            if maj1 == maj2 && lower + 1 == upper {
                return format!("elm {}.{}", maj1, min1);
            }
        }
    }
    package.elm_version.replace(" v ", " elm ")
}

fn escape<S>(user_agent: &String, str: S) -> String
where
    S: Into<String>,
{
    str.into()
        .replace("&", "&amp;")
        .replace("<=", "≤")
        .replace("<", if is_slack(user_agent) { "˂" } else { "&lt;" })
        .replace(">", "&gt;")
        .replace("\"", "&quot;")
        .replace("'", "&apos;")
}

fn item_comments(package: &Package) -> String {
    format!(
        "https://github.com/{}/{}/tree/{}.{}.{}",
        package.author, package.name, package.major, package.minor, package.patch
    )
}

fn item_categories(package: &Package) -> Vec<Category> {
    let mut categories: Vec<Category> = serde_json::from_str(&package.dependencies)
        .unwrap_or(HashMap::new())
        .into_iter()
        .map(|(pkg, constraint): (String, String)| dependency(&pkg, &constraint))
        .collect();

    categories.push(category(
        "elm",
        &format!("elm {}", &package.elm_version.replace("<=", "≤")),
    ));
    categories.push(category("license", &package.license));
    categories.sort_by(|c1, c2| c1.name().partial_cmp(c2.name()).unwrap());
    categories
}

fn dependency(pkg: &str, constraint: &str) -> Category {
    category(
        "dependency",
        &format!("{} {}", pkg, constraint.replace("<=", "≤")),
    )
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

fn item_content(package: &Package) -> String {
    let version = format!("{}.{}.{}", package.major, package.minor, package.patch);
    let mut dependencies: Vec<String> = serde_json::from_str(&package.dependencies)
        .unwrap_or(HashMap::new())
        .into_iter()
        .map(|(pkg, constraint): (String, String)| {
            format!("{} {}", pkg, constraint.replace("<=", "≤"))
        })
        .collect();
    dependencies.sort();

    format!(
        r#"
<img src="https://github.com/{author}.png?size=128"/>
<p>{description}</p>
<p>
 <strong>elm: </strong>{elm_version}<br>
 <strong>GitHub: </strong> <a href="https://github.com/{author}/{name}/tree/{version}">tree/{version}</a>
 <br>
 <strong>License: </strong><a href="https://spdx.org/licenses/{license}">{license}</a>
</p>
<p><strong>Dependencies: </strong><br>{dependencies}</p>
"#,
        author = package.author,
        name = package.name,
        version = version,
        description = package.summary,
        license = package.license,
        elm_version = package.elm_version.replace("<=", "≤"),
        dependencies = dependencies.join("<br>"),
    )
}
