use crate::db;
use crate::db::models::NewPackage;
use diesel::sqlite::SqliteConnection;
use reqwest::Client;
use std::collections::HashMap;

pub fn map<F>(f: F)
where
    F: Fn(&NewPackage),
{
    let url = format!("{}/all-packages", super::PACKAGES_URL);
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
            let elm = elm(&client, &pkg, &version);
            super::map_package(&f, 19, &pkg, &version, &elm, &releases.get(&version));
        }
    }
}

pub fn map_since<F>(f: F, from: i64, conn: &SqliteConnection)
where
    F: Fn(&NewPackage),
{
    let url = format!("{}/all-packages/since/{}", super::PACKAGES_URL, from);
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
        if db::has_package(conn, &pkg, 19) {
            continue;
        }
        let fields: Vec<&str> = pkg.split('@').collect();
        if let [repo, version] = &fields[..] {
            let releases = releases(&client, &repo);
            let elm = elm(&client, &repo, version);
            super::map_package(&f, 19, &repo, &version, &elm, &releases.get(*version));
        }
    }
}

fn elm(client: &Client, repo: &str, version: &str) -> Result<super::Json, ()> {
    let url = format!(
        "{}/packages/{}/{}/elm.json",
        super::PACKAGES_URL,
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
    let url = format!("{}/packages/{}/releases.json", super::PACKAGES_URL, repo);
    client
        .get(&url)
        .send()
        .and_then(|mut resp| resp.text())
        .map_err(|err| err.to_string())
        .and_then(|s| serde_json::from_str(&s).map_err(|err| err.to_string()))
        .map_err(|err| log::error!("can't get {} releases: {}", repo, err))
        .unwrap_or(HashMap::new())
}
