use serde::Serialize;
use sqlx::PgPool;
use chrono::{DateTime, Utc};
use sqlx::FromRow;

use crate::error::Result;
use crate::utils::{celsius_to_fahrenheit, compute_ratio, format_brew_time};

// Flattened struct for CSV export of a brew. This is what gets serialized and sent to the client
// (includes derived fields: ratio, water_temp_f, brew_time_display)
#[derive(Debug, Serialize)]
pub struct BrewExport {
    pub id: i32,
    pub brew_hash: Option<String>,
    pub brew_datetime: DateTime<Utc>,
    pub rating: Option<String>,
    pub grind_setting: Option<String>,
    pub coffee_grams: Option<f64>,
    pub water_grams: Option<f64>,
    pub ratio: Option<f64>,
    pub water_temp_c: Option<f64>,
    pub water_temp_f: Option<f64>,
    pub brew_time_secs: Option<i32>,
    pub brew_time_display: Option<String>,
    pub filter_paper: Option<String>,
    pub notes: Option<String>,
    pub review: Option<String>,
    // Bag info
    pub bag_hash: Option<String>,
    pub roaster: Option<String>,
    pub origin_country: Option<String>,
    pub origin_region: Option<String>,
    pub variety: Option<String>,
    pub process: Option<String>,
    pub roast_level: Option<String>,
    // Equipment
    pub grinder: Option<String>,
    pub brewer: Option<String>,
}


// Internal only, mirrors the raw SQL query result from the JOIN
// Never exposed outside this module
#[derive(Debug, FromRow)]
struct BrewQueryRow {
    id: i32,
    brew_hash: Option<String>,
    brew_datetime: DateTime<Utc>,
    rating: Option<String>,
    grind_setting: Option<String>,
    coffee_grams: Option<f64>,
    water_grams: Option<f64>,
    water_temp_c: Option<f64>,
    brew_time_secs: Option<i32>,
    filter_paper: Option<String>,
    notes: Option<String>,
    review: Option<String>,
    bag_hash: Option<String>,
    roaster: Option<String>,
    origin_country: Option<String>,
    origin_region: Option<String>,
    variety: Option<String>,
    process: Option<String>,
    roast_level: Option<String>,
    grinder_name: Option<String>,
    brewer_name: Option<String>,
}

impl From<BrewQueryRow> for BrewExport {
    fn from(r: BrewQueryRow) -> Self {
        BrewExport {
            id: r.id,
            brew_hash: r.brew_hash,
            brew_datetime: r.brew_datetime,
            rating: r.rating,
            grind_setting: r.grind_setting,
            coffee_grams: r.coffee_grams,
            water_grams: r.water_grams,
            ratio: compute_ratio(r.coffee_grams, r.water_grams),
            water_temp_c: r.water_temp_c,
            water_temp_f: celsius_to_fahrenheit(r.water_temp_c),
            brew_time_secs: r.brew_time_secs,
            brew_time_display: format_brew_time(r.brew_time_secs),
            filter_paper: r.filter_paper,
            notes: r.notes,
            review: r.review,
            bag_hash: r.bag_hash,
            roaster: r.roaster,
            origin_country: r.origin_country,
            origin_region: r.origin_region,
            variety: r.variety,
            process: r.process,
            roast_level: r.roast_level,
            grinder: r.grinder_name,
            brewer: r.brewer_name,
        }
    }
}

// Fetch all brews with related data joined (DESC, newest first)
pub async fn all_brews_export(pool: &PgPool) -> Result<Vec<BrewExport>> {
    let rows: Vec<BrewQueryRow> = sqlx::query_as!(
        BrewQueryRow,
        r#"SELECT
            b.id,
            b.brew_hash,
            b.brew_datetime,
            b.rating,
            b.grind_setting,
            b.coffee_grams,
            b.water_grams,
            b.water_temp_c,
            b.brew_time_secs,
            b.filter_paper,
            b.notes,
            b.review,
            cb.bag_hash,
            cb.roaster,
            cb.origin_country,
            cb.origin_region,
            cb.variety,
            cb.process,
            cb.roast_level,
            g.name  AS grinder_name,
            br.name AS brewer_name
           FROM brews b
           LEFT JOIN coffee_bags cb ON b.coffee_bag_id = cb.id
           LEFT JOIN grinders g     ON b.grinder_id    = g.id
           LEFT JOIN brewers  br    ON b.brewer_id      = br.id
           ORDER BY b.brew_datetime DESC"#
    )
    .fetch_all(pool)
    .await?;

    let export: Vec<BrewExport> = rows.into_iter().map(|r| {
        let ratio: Option<f64> = match (r.coffee_grams, r.water_grams) {
            (Some(c), Some(w)) if c > 0.0 => Some((w / c * 10.0).round() / 10.0),
            _ => None,
        };
        // TODO: Make this into a function instead
        let water_temp_f: Option<f64> = r.water_temp_c.map(|c: f64| c * 9.0 / 5.0 + 32.0);
        let brew_time_display: Option<String> = r.brew_time_secs
            .map(|s: i32| format!("{:02}:{:02}", s / 60, s % 60));

        BrewExport {
            id: r.id,
            brew_hash: r.brew_hash,
            brew_datetime: r.brew_datetime,
            rating: r.rating,
            grind_setting: r.grind_setting,
            coffee_grams: r.coffee_grams,
            water_grams: r.water_grams,
            ratio,
            water_temp_c: r.water_temp_c,
            water_temp_f,
            brew_time_secs: r.brew_time_secs,
            brew_time_display,
            filter_paper: r.filter_paper,
            notes: r.notes,
            review: r.review,
            bag_hash: r.bag_hash,
            roaster: r.roaster,
            origin_country: r.origin_country,
            origin_region: r.origin_region,
            variety: r.variety,
            process: r.process,
            roast_level: r.roast_level,
            grinder: r.grinder_name,
            brewer: r.brewer_name,
        }
    }).collect();

    Ok(export)
}


// A single data point for grind size analytics.
// Used to plot grind setting vs rating per coffee bag.
#[derive(Debug, Serialize)]
pub struct GrindDataPoint {
    pub brew_hash: Option<String>,
    pub brew_datetime: DateTime<Utc>,
    pub grind_setting: Option<String>,
    pub rating: Option<String>,
    pub bag_hash: Option<String>,
    pub roaster: Option<String>,
}

// Fetch grind settings and ratings for a specific bag.
// The mobile app uses this to plot grind vs rating over time.
pub async fn grind_analytics(pool: &PgPool, coffee_bag_id: i32) -> Result<Vec<GrindDataPoint>> {
    let rows = sqlx::query!(
        r#"SELECT
            b.brew_hash,
            b.brew_datetime,
            b.grind_setting,
            b.rating,
            cb.bag_hash,
            cb.roaster
           FROM brews b
           LEFT JOIN coffee_bags cb ON b.coffee_bag_id = cb.id
           WHERE b.coffee_bag_id = $1
             AND b.grind_setting IS NOT NULL
           ORDER BY b.brew_datetime ASC"#,
        coffee_bag_id
    )
    .fetch_all(pool)
    .await?;

    let points: Vec<GrindDataPoint> = rows.into_iter().map(|r| GrindDataPoint {
        brew_hash: r.brew_hash,
        brew_datetime: r.brew_datetime,
        grind_setting: r.grind_setting,
        rating: r.rating,
        bag_hash: r.bag_hash,
        roaster: r.roaster,
    }).collect();

    Ok(points)
}

