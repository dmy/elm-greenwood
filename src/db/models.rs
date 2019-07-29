use super::schema::packages;

/// Formats:
/// 19: elm.json
///     Some older packages have been converted  on official server, but not all.
/// 15: elm-package.json, including "elm-version"
///     Some older packages have been converted  on official server, but not all.
/// 14: elm-package.json, without "elm-version"
/// 13: elm_dependencies.json, the file does not seem to exist on the server
///     The packages in this format are not saved for now and produce an error
///     in the logs because of the missing "elm-version" field.

#[derive(Queryable)]
pub struct Package {
    pub id: i32,
    pub timestamp: i64,
    pub major: i32,
    pub minor: i32,
    pub patch: i32,
    pub author: String,
    pub name: String,
    pub summary: String,
    pub license: String,
    pub elm_version: String,
    pub dependencies: String,
    pub format: i32,
}

#[derive(Insertable, Debug)]
#[table_name = "packages"]
pub struct NewPackage<'a> {
    pub timestamp: &'a i64,
    pub major: i32,
    pub minor: i32,
    pub patch: i32,
    pub author: &'a str,
    pub name: &'a str,
    pub summary: &'a str,
    pub license: &'a str,
    pub elm_version: &'a str,
    pub dependencies: &'a str,
    pub format: i32,
}
