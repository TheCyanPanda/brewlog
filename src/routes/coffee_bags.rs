use axum::{
    Router, Json,
    extract::{Path, State},
    routing::{get, post},
};
use sqlx::PgPool;

use crate::{
    error::{AppError, Result},
    hash::make_bag_hash,
    models::{CoffeeBag,CreateCoffeeBag},
};

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/bags", get(list_bags).post(create_bag))
        .route("/bags/:id", get(get_bag).put(update_bag).delete(delete_bag))
}


// GET /bags
async fn list_bags(State(pool): State<PgPool>) -> Result<Json<Vec<CoffeeBag>>> {
    let bags = sqlx::query_as!(
        CoffeeBag,
        r#"SELECT * FROM coffee_bags ORDER BY created_at DESC"#
    )
    .fetch_all(&pool)
    .await?;

    Ok(Json(bags))
}


// POST /bags
async fn create_bag(
    State(pool): State<PgPool>,
    Json(body): Json<CreateCoffeeBag>,
) -> Result<Json<CoffeeBag>> {
    let bag = sqlx::query_as!(
    CoffeeBag,
    r#"INSERT INTO coffee_bags
       (roaster, roaster_origin_city, roaster_origin_country,
       origin_country, origin_region, roast_level, variety, process,
       taste_notes, bean_type, harvest_date, roast_date, caffeine_free,
       batch_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
       RETURNING id, bag_hash, roaster, roaster_origin_city, roaster_origin_country,
                 origin_country, origin_region, roast_level, variety, process,
                 taste_notes, bean_type, harvest_date, roast_date, caffeine_free,
                 batch_id, image_path, created_at"#,
    body.roaster,
    body.roaster_origin_city,
    body.roaster_origin_country,
    body.origin_country,
    body.origin_region,
    body.roast_level,
    body.variety,
    body.process,
    body.taste_notes.as_deref(), // Option<Vec<String>> -> Option<&^[String]>
    body.bean_type,
    body.harvest_date,
    body.roast_date,
    body.caffeine_free.unwrap_or(false),
    body.batch_id,
    )
    .fetch_one(&pool)
    .await?;

    // Generate the hash using the assigned ID and update the row with the hash
    let bag_hash = make_bag_hash(body.roaster.as_deref(), bag.id);
    let bag = sqlx::query_as!(
        CoffeeBag,
        r#"UPDATE coffee_bags SET bag_hash = $1 WHERE id = $2
        RETURNING id, bag_hash, roaster, roaster_origin_city, roaster_origin_country,
                  origin_country, origin_region, roast_level, variety, process,
                  taste_notes, bean_type, harvest_date, roast_date, caffeine_free,
                  batch_id, image_path, created_at"#,
        bag_hash,
        bag.id
    )
    .fetch_one(&pool)
    .await?;

    Ok(Json(bag))
}


// /GET bags:id
async fn get_bag(
    State(pool): State<PgPool>,
    Path(id): Path<i32>
) -> Result<Json<CoffeeBag>> {
    let bag: CoffeeBag = sqlx::query_as!(
        CoffeeBag,
        r#"SELECT id, bag_hash, roaster, roaster_origin_city, roaster_origin_country,
          origin_country, origin_region, roast_level, variety, process,
          taste_notes, bean_type, harvest_date, roast_date, caffeine_free,
          batch_id, image_path, created_at
        FROM coffee_bags WHERE id = $1"#,
        id
    )
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound(format!("Bag {} not found", id)))?;

    Ok(Json(bag))

}

async fn update_bag(
    State(pool): State<PgPool>,
    Path(id): Path<i32>,
    Json(body): Json<CreateCoffeeBag>,
) -> Result<Json<CoffeeBag>> {
    let bag: CoffeeBag = sqlx::query_as!(
        CoffeeBag,
        r#"UPDATE coffee_bags SET
            roaster = $1, roaster_origin_city = $2, roaster_origin_country = $3,
            origin_country = $4, origin_region = $5, variety = $6, process = $7,
            taste_notes = $8, bean_type = $9, roast_level = $10,
            harvest_date = $11, roast_date = $12,
            caffeine_free = $13, batch_id = $14
           WHERE id = $15
           RETURNING id, bag_hash, roaster, roaster_origin_city, roaster_origin_country,
                     origin_country, origin_region, variety, process, taste_notes,
                     bean_type, roast_level, harvest_date, roast_date, caffeine_free,
                     batch_id, image_path, created_at"#,
        body.roaster, body.roaster_origin_city, body.roaster_origin_country,
        body.origin_country, body.origin_region, body.variety, body.process,
        body.taste_notes.as_deref(), body.bean_type, body.roast_level,
        body.harvest_date, body.roast_date,
        body.caffeine_free.unwrap_or(false), body.batch_id,
        id
    )
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound(format!("Bag {} not found", id)))?;

    Ok(Json(bag))
}

async fn delete_bag(
    State(pool): State<PgPool>,
    Path(id): Path<i32>,
) -> Result<Json<serde_json::Value>> {
    let result: sqlx::postgres::PgQueryResult = sqlx::query!(
        "DELETE FROM coffee_bags WHERE id = $1",
        id
    )
    .execute(&pool)
    .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound(format!("Bag {} not found", id)));
    }

    Ok(Json(serde_json::json!({ "deleted": id })))
}
