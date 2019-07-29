pub mod old_packages;
pub mod packages;
use crate::db::models::NewPackage;
use serde::Deserialize;
use std::collections::HashMap;

pub const PACKAGES_URL: &str = "https://package.elm-lang.org";

#[derive(Debug, Deserialize)]
struct Json {
    summary: String,
    license: String,
    #[serde(rename = "elm-version")]
    elm_version: String,
    dependencies: HashMap<String, String>,
}

fn map_package<F>(f: F, pkg: &str, version: &str, elm: &Result<Json, ()>, timestamp: &Option<&i64>)
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
        elm,
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
    } else {
        log::error!("Ignoring invalid package {} {}", pkg, version);
    }
}
