use crate::db;
use crate::db::models::NewPackage;
use diesel::sqlite::SqliteConnection;
use reqwest::header::LAST_MODIFIED;
use reqwest::Client;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct OldPackage {
    pub name: String,
    pub summary: String,
    pub versions: Vec<String>,
}

pub fn map<F>(f: F, conn: &SqliteConnection)
where
    F: Fn(&NewPackage),
{
    let client = Client::new();
    let pkgs: Vec<OldPackage> = client
        // The trick is to use HTTP with elm-package-version=0.18 to connect to the old server
        .get("http://package.elm-lang.org/all-packages?elm-package-version=0.18")
        .send()
        .and_then(|mut resp| resp.text())
        .map_err(|err| err.to_string())
        .and_then(|s| serde_json::from_str(&s).map_err(|err| err.to_string()))
        .map_err(|err| log::error!("can't get old format packages: {}", err))
        .unwrap_or(vec![]);

    for pkg in pkgs {
        // First quickly find missing packages
        if !db::has_old_format_package_versions(conn, &pkg.name, &pkg.versions) {
            // Then find exact version
            for version in pkg.versions {
                if !db::has_old_format_package_version(conn, &pkg.name, &version) {
                    let (elm, timestamp) = elm_package(&client, &pkg.name, &version);
                    super::map_package(&f, 15, &pkg.name, &version, &elm, &timestamp.as_ref());
                }
            }
        }
    }
}

fn elm_package(
    client: &Client,
    name: &String,
    version: &String,
) -> (Result<super::Json, ()>, Option<i64>) {
    let url = format!(
        "http://package.elm-lang.org/packages/{}/{}/elm-package.json?elm-package-version=0.18",
        name, version
    );
    let resp = client.get(&url).send();

    let last_modified = resp
        .as_ref()
        .ok()
        .and_then(|r| r.headers().get(LAST_MODIFIED))
        .map(|header| header.to_str())
        .and_then(|s| s.ok())
        .and_then(|rfc2822_datetime| chrono::DateTime::parse_from_rfc2822(rfc2822_datetime).ok())
        .map(|datetime| datetime.timestamp());

    let elm = resp
        .and_then(|mut resp| resp.text())
        .map_err(|err| err.to_string())
        .and_then(|s| serde_json::from_str(&s).map_err(|err| err.to_string()))
        .map_err(|err| log::error!("can't get {} {} elm.json: {}", name, version, err));

    (elm, last_modified)
}
