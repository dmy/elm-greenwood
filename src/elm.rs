pub mod old_format_packages;
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
    #[serde(default = "default_elm_version")]
    elm_version: String,
    dependencies: HashMap<String, String>,
}

fn default_elm_version() -> String {
    "".to_string()
}

fn map_package<F>(
    f: F,
    format: i32,
    pkg: &str,
    version: &str,
    elm: &Result<Json, ()>,
    timestamp: &Option<&i64>,
) where
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
            elm_version: match elm.elm_version.as_ref() {
                // elm-version did not exist for 0.14 and
                // packages < 0.14 are not listed
                "" => "0.14.0 <= v < 0.15.0",
                _ => &elm.elm_version,
            },
            dependencies: &serde_json::json!(elm.dependencies).to_string(),
            format: match elm.elm_version.as_ref() {
                "" => 14,
                _ => format,
            },
        };
        f(&package);
    } else {
        log::error!("Ignoring invalid package {} {}", pkg, version);
    }
}
