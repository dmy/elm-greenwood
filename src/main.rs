#[macro_use]
extern crate diesel;
extern crate dotenv;

mod db;
mod elm;
mod release;
mod rss;

use db::models::*;
use dotenv::dotenv;
use release::Release;
use std::collections::HashMap;
use std::env;
use std::thread;
use std::time::Duration;
use syslog::Facility;
use warp::filters::BoxedFilter;
use warp::reply::Reply;
use warp::Filter;

fn main() -> syslog::Result<()> {
    syslog::init(Facility::LOG_USER, log::LevelFilter::Info, None)?;

    dotenv().ok();
    let www_root = env::var("WWW_ROOT").unwrap_or("./web/static".to_string());
    log::info!("Serving files from {}", www_root);
    let db_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    log::info!("Using {} database", db_url);

    thread::spawn(|| loop {
        update_packages();
        thread::sleep(Duration::from_secs(60));
    });

    let rss = rss_packages(None, &Release::Any);
    let rss_last = rss_packages(Some("last"), &Release::Last);
    let rss_first = rss_packages(Some("first"), &Release::First);
    let rss_major = rss_packages(Some("major"), &Release::Major);
    let rss_minor = rss_packages(Some("minor"), &Release::Minor);
    let rss_patch = rss_packages(Some("patch"), &Release::Patch);

    let default = warp::any().and(warp::fs::file(format!("{}/index.html", www_root)));
    let public = warp::get2().and(warp::fs::dir(www_root));

    let routes = rss
        .or(rss_last)
        .or(rss_first)
        .or(rss_major)
        .or(rss_minor)
        .or(rss_patch)
        .or(public)
        .or(default);

    warp::serve(routes).run(([127, 0, 0, 1], 4242));
    Ok(())
}

pub fn update_packages() {
    let conn = db::connect();
    let pkgs_count = db::count_packages(&conn);
    let save = |pkg: &NewPackage| {
        log::info!("Adding {:?}", pkg);
        db::save_package(&conn, pkg);
    };

    if pkgs_count == 0 {
        log::info!("Retrieving all packages");
        elm::all_packages::map(save);
    } else {
        log::info!("Updating packages since {}", pkgs_count);
        elm::all_packages::map_since(save, pkgs_count);
    }
}

fn rss_packages(
    path: Option<&'static str>,
    release: &'static Release,
) -> BoxedFilter<(impl Reply,)> {
    warp::get2()
        .and(match path {
            Some(path) => warp::path(path).boxed(),
            None => warp::any().boxed(),
        })
        .and(warp::path(".rss"))
        .and(warp::query::<HashMap<String, String>>())
        .map(move |query| rss::all(query, release))
        .with(warp::reply::with::header("content-type", "application/xml"))
        .boxed()
}
