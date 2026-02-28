use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

use crate::utils::{celsius_to_fahrenheit, compute_ratio, format_brew_time};

// ======= Users =======

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct User {
    pub id: i32,
    pub username: String,
    pub display_name: Option<String>,
    pub email: Option<String>,
    #[serde(skip_serializing)]  // never expose the hash in API responses
    pub password_hash: String,
    pub is_admin: bool,
    pub created_at: DateTime<Utc>,
}

// Registration input — plain-text password, hashed server-side before storage
#[derive(Debug, Deserialize)]
pub struct CreateUser {
    pub username: String,
    pub display_name: Option<String>,
    pub email: Option<String>,
    pub password: String,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct UserToken {
    pub id: i32,
    pub user_id: i32,
    #[serde(skip_serializing)]  // raw token is only ever held by the client
    pub token_hash: String,
    pub label: Option<String>,
    pub expires_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}

// ======= Equipment =======

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Grinder {
    pub id: i32,
    pub user_id: i32,
    pub name: String,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateGrinder {
    pub name: String,
    pub notes: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Brewer {
    pub id: i32,
    pub user_id: i32,
    pub name: String,
    pub brew_method: String,        // filter, espresso, other
    pub brew_type: Option<String>,  // v60, chemex, aeropress, automatic
    pub brand: Option<String>,
    pub model: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}


#[derive(Debug, Serialize, Deserialize)]
pub struct CreateBrewer {
    pub name: String,
    pub brew_method: String,
    pub brew_type: Option<String>,
    pub brand: Option<String>,
    pub model: Option<String>,
    pub notes: Option<String>,
}

// ====== Coffee bags ======


#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct CoffeeBag {
    pub id: i32,
    pub user_id: i32,
    pub bag_hash: Option<String>,
    pub roaster: Option<String>,
    pub roaster_origin_city: Option<String>,
    pub roaster_origin_country: Option<String>,
    pub origin_country: Option<String>,
    pub origin_region: Option<String>,
    pub roast_level: Option<String>,
    pub variety: Option<String>,
    pub process: Option<String>,
    pub taste_notes: Option<Vec<String>>,
    pub bean_type: Option<String>,
    pub harvest_date: Option<NaiveDate>,
    pub roast_date: Option<NaiveDate>,
    pub caffeine_free: bool,
    pub batch_id: Option<String>,
    pub image_path: Option<String>,
    pub created_at: DateTime<Utc>,
}


#[derive(Debug, Serialize, Deserialize)]
pub struct CreateCoffeeBag {
    pub roaster: Option<String>,
    pub roaster_origin_city: Option<String>,
    pub roaster_origin_country: Option<String>,
    pub origin_country: Option<String>,
    pub origin_region: Option<String>,
    pub roast_level: Option<String>,
    pub variety: Option<String>,
    pub process: Option<String>,
    pub taste_notes: Option<Vec<String>>,
    pub bean_type: Option<String>,
    pub harvest_date: Option<NaiveDate>,
    pub roast_date: Option<NaiveDate>,
    pub caffeine_free: Option<bool>,
    pub batch_id: Option<String>,
}

// ====== Brews

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Brew {
    pub id: i32,
    pub user_id: i32,
    pub brew_hash: Option<String>,
    pub coffee_bag_id: Option<i32>,
    pub brew_datetime: DateTime<Utc>,
    pub grinder_id: Option<i32>,
    pub grind_setting: Option<String>,
    pub brewer_id: Option<i32>,
    pub filter_paper: Option<String>,
    pub coffee_grams: Option<f64>,
    pub water_grams: Option<f64>,
    pub water_temp_c: Option<f64>,
    pub brew_time_secs: Option<i32>,
    pub brew_steps: Option<serde_json::Value>,
    pub rating: Option<String>,
    pub review: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>
}

impl Brew {
    // Compute ratio from stored grams (stored as 1:f64, eg: 15g coffee / 250g water = 1:16.7)
    pub fn ratio(&self) -> Option<f64> {
        compute_ratio(self.coffee_grams, self.water_grams)
    }

    // Convert from Celcius -> Farenheit
    pub fn water_temp_f(&self) -> Option<f64> {
        celsius_to_fahrenheit(self.water_temp_c)
    }

    // Format brew_time_secs as 'MM:SS' String
    pub fn brew_time_display(&self) -> Option<String> {
        format_brew_time(self.brew_time_secs)
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateBrew {
    pub coffee_bag_id: Option<i32>,
    pub brew_datetime: Option<DateTime<Utc>>, // defaults to now() if omitted

    pub grinder_id: Option<i32>,
    pub grind_setting: Option<String>,
    pub brewer_id: Option<i32>,
    pub filter_paper: Option<String>,

    pub coffee_grams: Option<f64>,
    pub water_grams: Option<f64>,
    pub water_temp_c: Option<f64>,
    pub brew_time_secs: Option<i32>,  // pass as seconds; UI converts mm:ss → seconds

    pub brew_steps: Option<serde_json::Value>,

    pub rating: Option<String>,
    pub review: Option<String>,
    pub notes: Option<String>,
}

// A brew with derived fields included - used in API responses
#[derive(Debug, Serialize)]
pub struct BrewResponse {
    #[serde(flatten)]
    pub brew: Brew,
    pub ratio: Option<f64>,
    pub water_temp_f: Option<f64>,
    pub brew_time_display: Option<String>,
}

impl From<Brew> for BrewResponse {
    fn from(brew: Brew) -> Self {
        let ratio = brew.ratio();
        let water_temp_f = brew.water_temp_f();
        let brew_time_display = brew.brew_time_display();
        Self { brew, ratio, water_temp_f, brew_time_display }
    }
}

// Query filters
/// Query params for GET /brews — e.g. ?rating=excellent&origin_country=Ethiopia
#[derive(Debug, Deserialize)]
pub struct BrewFilter {
    pub rating: Option<String>,
    pub coffee_bag_id: Option<i32>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

