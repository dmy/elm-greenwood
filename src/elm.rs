pub const PACKAGES_URL: &str = "https://package.elm-lang.org";
pub mod all_packages {
    use crate::db::models::NewPackage;
    use crate::elm;
    use reqwest::Client;
    use serde::Deserialize;
    use std::collections::HashMap;

    pub fn map<F>(f: F)
    where
        F: Fn(&NewPackage),
    {
        let url = format!("{}/all-packages", elm::PACKAGES_URL);
        let client = Client::new();
        let pkgs: HashMap<String, Vec<String>> = client
            .get(&url)
            .send()
            .and_then(|mut resp| resp.text())
            .map_err(|err| err.to_string())
            .and_then(|s| serde_json::from_str(&s).map_err(|err| err.to_string()))
            .map_err(|err| log::error!("can't get all packages: {}", err))
            .unwrap_or(HashMap::new());

        log::info!("{} packages found", pkgs.len());

        for (pkg, versions) in pkgs {
            let releases = releases(&client, &pkg);
            for version in versions {
                map_package(&f, &client, &pkg, &version, releases.get(&version));
            }
        }
    }

    pub fn map_since<F>(f: F, from: i64)
    where
        F: Fn(&NewPackage),
    {
        let url = format!("{}/all-packages/since/{}", elm::PACKAGES_URL, from);
        let client = Client::new();
        let pkgs: Vec<String> = client
            .get(&url)
            .send()
            .and_then(|mut resp| resp.text())
            .map_err(|err| err.to_string())
            .and_then(|s| serde_json::from_str(&s).map_err(|err| err.to_string()))
            .map_err(|err| log::error!("can't get packages since {}: {}", from, err))
            .unwrap_or(Vec::new());

        log::info!("{} new packages", pkgs.len());

        for pkg in pkgs {
            let fields: Vec<&str> = pkg.split('@').collect();
            if let [repo, version] = &fields[..] {
                let releases = releases(&client, &repo);
                map_package(&f, &client, &repo, &version, releases.get(*version));
            }
        }
    }

    fn map_package<F>(f: F, client: &Client, pkg: &str, version: &str, timestamp: Option<&i64>)
    where
        F: Fn(&NewPackage),
    {
        let repo: Vec<&str> = pkg.split('/').collect();
        let semver: Vec<&str> = version.split('.').collect();

        if let (
            Some(author),
            Some(name),
            Some(timestamp),
            Ok(elm),
            Some(major),
            Some(minor),
            Some(patch),
        ) = (
            repo.get(0),
            repo.get(1),
            timestamp,
            elm(client, pkg, version),
            semver.get(0).and_then(|s| s.parse::<i32>().ok()),
            semver.get(1).and_then(|s| s.parse::<i32>().ok()),
            semver.get(2).and_then(|s| s.parse::<i32>().ok()),
        ) {
            let package = NewPackage {
                timestamp,
                major,
                minor,
                patch,
                author,
                name: name,
                summary: &elm.summary,
                license: &elm.license,
                elm_version: &elm.elm_version,
                dependencies: &serde_json::json!(elm.dependencies).to_string(),
            };
            f(&package);
        }
    }

    #[derive(Debug, Deserialize)]
    struct Elm {
        summary: String,
        license: String,
        #[serde(rename = "elm-version")]
        elm_version: String,
        dependencies: HashMap<String, String>,
    }

    fn elm(client: &Client, repo: &str, version: &str) -> Result<Elm, ()> {
        let url = format!(
            "{}/packages/{}/{}/elm.json",
            elm::PACKAGES_URL,
            repo,
            version
        );
        client
            .get(&url)
            .send()
            .and_then(|mut resp| resp.text())
            .map_err(|err| err.to_string())
            .and_then(|s| serde_json::from_str(&s).map_err(|err| err.to_string()))
            .map_err(|err| log::error!("can't get {} {} elm.json: {}", repo, version, err))
    }

    fn releases(client: &Client, repo: &str) -> HashMap<String, i64> {
        let url = format!("{}/packages/{}/releases.json", elm::PACKAGES_URL, repo);
        client
            .get(&url)
            .send()
            .and_then(|mut resp| resp.text())
            .map_err(|err| err.to_string())
            .and_then(|s| serde_json::from_str(&s).map_err(|err| err.to_string()))
            .map_err(|err| log::error!("can't get {} releases: {}", repo, err))
            .unwrap_or(HashMap::new())
    }

}
