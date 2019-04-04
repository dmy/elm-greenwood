use super::schema::packages;

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
}
