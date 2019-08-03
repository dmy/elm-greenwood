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
        update_outcast_packages();
        for _ in 0..59 {
            update_packages();
            thread::sleep(Duration::from_secs(60));
        }
    });

    let get_rss = rss_packages(None, &Release::Any);
    let get_rss_last = rss_packages(Some("last"), &Release::Last);
    let get_rss_first = rss_packages(Some("first"), &Release::First);
    let get_rss_major = rss_packages(Some("major"), &Release::Major);
    let get_rss_minor = rss_packages(Some("minor"), &Release::Minor);
    let get_rss_patch = rss_packages(Some("patch"), &Release::Patch);

    // we should set the date with the more recent pubDate
    let head_rss = warp::head().and(warp::path(".rss")).map(warp::reply);

    let default = warp::any().and(warp::fs::file(format!("{}/index.html", www_root)));
    let get_static = warp::get2().and(warp::fs::dir(www_root));

    let routes = get_rss
        .or(get_rss_last)
        .or(get_rss_first)
        .or(get_rss_major)
        .or(get_rss_minor)
        .or(get_rss_patch)
        .or(head_rss)
        .or(get_static)
        .or(default);

    warp::serve(routes).run(([127, 0, 0, 1], 4242));
    Ok(())
}

pub fn update_packages() {
    let conn = db::connect();
    let pkgs_count = db::count_packages(&conn, 19);
    let save = |pkg: &NewPackage| db::save_package(&conn, pkg);

    if pkgs_count == 0 {
        log::info!("Retrieving all packages");
        elm::packages::map(save);
    } else {
        log::info!("Updating packages since {}", pkgs_count);
        elm::packages::map_since(save, pkgs_count);
    }
}

/// 0.18 packages published after 0.19.0 release and some older
/// ones are ignored by the packages API released with 0.19.0.
pub fn update_outcast_packages() {
    let conn = db::connect();
    let save = |pkg: &NewPackage| db::save_package(&conn, pkg);

    log::info!("Updating old format packages");
    elm::old_format_packages::map(save, &conn);
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
        .and(warp::header("user-agent"))
        .and(warp::query::<HashMap<String, String>>())
        .map(move |user_agent, query| rss::all(user_agent, query, release))
        .with(warp::reply::with::header("content-type", "application/xml"))
        .boxed()
}
