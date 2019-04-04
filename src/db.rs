use crate::release::Release;
use diesel::dsl::*;
use diesel::prelude::*;
use diesel::sql_types::Text;
use diesel::sqlite::SqliteConnection;
use dotenv::dotenv;
use models::{NewPackage, Package};
use schema::packages;
use schema::packages::dsl::*;
use std::collections::HashMap;
use std::env;

pub mod models;
pub mod schema;

const PACKAGES_NUMBER: i64 = 42;

pub fn connect() -> SqliteConnection {
    dotenv().ok();

    let db_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");

    SqliteConnection::establish(&db_url).expect(&format!("Error connecting to {}", db_url))
}

pub fn count_packages(conn: &SqliteConnection) -> i64 {
    packages
        .select(count_star())
        .get_result(conn)
        .expect("Can't count packages from database")
}

pub fn save_package(conn: &SqliteConnection, pkg: &NewPackage) {
    diesel::insert_into(packages::table)
        .values(pkg)
        .execute(conn)
        .expect("Can't insert package into database");
}

pub fn last_packages(
    conn: &SqliteConnection,
    filter: &HashMap<String, String>,
    release: &Release,
) -> Vec<Package> {
    let mut query = packages
        .order(timestamp.desc())
        .limit(PACKAGES_NUMBER)
        .into_boxed();

    let pkgs = query_packages(conn, filter);
    if !filter.is_empty() {
        query = query.filter(author.concat("/").concat(name).eq_any(pkgs))
    };

    query = match release {
        Release::Any => query,
        Release::Last => query.group_by(sql::<Text>("author,name HAVING MAX(timestamp)")),
        Release::First => query.filter(major.eq(1).and(minor.eq(0)).and(patch.eq(0))),
        Release::Major => query.filter(minor.eq(0).and(patch.eq(0))),
        Release::Minor => query.filter(minor.ne(0).and(patch.eq(0))),
        Release::Patch => query.filter(patch.ne(0)),
    };
    let debug = diesel::debug_query::<diesel::sqlite::Sqlite, _>(&query);
    log::info!("{}", debug.to_string());

    query
        .load::<Package>(conn)
        .expect("Can't load packages from database")
}

fn query_packages(conn: &SqliteConnection, filter: &HashMap<String, String>) -> Vec<String> {
    filter
        .iter()
        .flat_map(|(owner, names)| expand_packages(conn, owner, names))
        .collect()
}

fn expand_packages(conn: &SqliteConnection, user: &String, expr: &String) -> Vec<String> {
    let mut pkgs: Vec<String> = expr.split(" ").map(String::from).collect();

    if pkgs.contains(&"*".to_string()) {
        pkgs = author_packages(conn, &user);
    }
    pkgs.into_iter()
        .map(move |pkg| (format!("{}/{}", user.to_string(), pkg)))
        .collect()
}

pub fn author_packages(conn: &SqliteConnection, user: &String) -> Vec<String> {
    packages
        .select(name)
        .distinct()
        .filter(author.eq(user))
        .order(timestamp.desc())
        .limit(PACKAGES_NUMBER)
        .load::<String>(conn)
        .expect(&format!("Cant load {} packages from database", user))
}
