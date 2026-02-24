// src/routes/ha.rs
//
// Lightweight endpoints for Home Assistant REST sensor integration.
//
// In HA configuration.yaml:
//
//   sensor:
//     - platform: rest
//       name: "Latest Brew"
//       resource: http://YOUR_SERVER_IP:3000/ha/latest_brew
//       value_template: "{{ value_json.brew_hash }}"
//       json_attributes:
//         - rating
//         - coffee
//         - grind_setting
//         - ratio
//         - water_temp_c
//
//     - platform: rest
//       name: "Today's Brew Count"
//       resource: http://YOUR_SERVER_IP:3000/ha/stats/today
//       value_template: "{{ value_json.brew_count }}"

use axum::{extract::State, routing::get, Json, Router};
use chrono::Utc;
use serde::Serialize;
use sqlx::PgPool;

use crate::error::Result;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/ha/latest_brew", get(latest_brew))
        .route("/ha/stats/today", get(stats_today))
}

#[derive(Serialize)]
pub struct LatestBrew {
    pub brew_hash: Option<String>,
    pub rating: Option<String>,
    pub coffee: Option<String>,  // Roaster and origin of coffe bag
    pub grind_setting: Option<String>,
    pub ratio: Option<f64>,
    pub water_temp_c: Option<f64>,
    pub water_temp_f: Option<f64>,
    pub brew_time_display: Option<String>,
    pub brew_datetime: Option<chrono::DateTime<Utc>>,
}

async fn latest_brew(State(pool): State<PgPool>) -> Result<Json<LatestBrew>> {
    // Join brews with coffee_bags to get coffee name
    let row = sqlx::query!(
        r#"SELECT b.brew_hash, b.rating, b.grind_setting,
                  b.coffee_grams, b.water_grams, b.water_temp_c,
                  b.brew_time_secs, b.brew_datetime,
                  cb.roaster, cb.origin_country
           FROM brews b
           LEFT JOIN coffee_bags cb ON b.coffee_bag_id = cb.id
           ORDER BY b.brew_datetime DESC
           LIMIT 1"#
    )
    .fetch_optional(&pool)
    .await?;

    let result = match row {
        None => LatestBrew {
            brew_hash: None, rating: None, coffee: None,
            grind_setting: None, ratio: None, water_temp_c: None,
            water_temp_f: None, brew_time_display: None, brew_datetime: None,
        },
        Some(r) => {
            let ratio = match (r.coffee_grams, r.water_grams) {
                (Some(c), Some(w)) if c > 0.0 => Some(
                    // Round to 1 decimal for HA display
                    (w / c * 10.0).round() / 10.0
                ),
                _ => None,
            };

            let coffee = match (r.roaster, r.origin_country) {
                (Some(roaster), Some(origin)) => Some(format!("{} — {}", roaster, origin)),
                (Some(roaster), None) => Some(roaster),
                _ => None,
            };

            let brew_time_display = r.brew_time_secs.map(|s| {
                format!("{:02}:{:02}", s / 60, s % 60)
            });

            // temp C -> F
            let water_temp_f: Option<f64> = r.water_temp_c.map(|c: f64| c * 9.0 / 5.0 + 32.0);
            LatestBrew {
                brew_hash: r.brew_hash,
                rating: r.rating,
                coffee,
                grind_setting: r.grind_setting,
                ratio,
                water_temp_c: r.water_temp_c.map(|t| t),
                water_temp_f,
                brew_time_display,
                brew_datetime: Some(r.brew_datetime),
            }
        }
    };

    Ok(Json(result))
}

#[derive(Serialize)]
struct TodayStats {
    brew_count: i64,
    ratings: serde_json::Value,  // counts per rating level
}

async fn stats_today(State(pool): State<PgPool>) -> Result<Json<TodayStats>> {
    let brew_count: i64 = sqlx::query_scalar!(
        "SELECT COUNT(*) FROM brews WHERE brew_datetime >= CURRENT_DATE"
    )
    .fetch_one(&pool)
    .await?
    .unwrap_or(0);

    // Count per rating for today
    let rating_rows = sqlx::query!(
        r#"SELECT rating, COUNT(*) as count
           FROM brews
           WHERE brew_datetime >= CURRENT_DATE AND rating IS NOT NULL
           GROUP BY rating"#
    )
    .fetch_all(&pool)
    .await?;

    let mut ratings = serde_json::Map::new();
    for row in rating_rows {
        if let Some(r) = row.rating {
            ratings.insert(r, serde_json::json!(row.count.unwrap_or(0)));
        }
    }

    Ok(Json(TodayStats {
        brew_count,
        ratings: serde_json::Value::Object(ratings),
    }))
}

