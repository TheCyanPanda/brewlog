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
use crate::auth::AuthUser;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/bags", get(list_bags).post(create_bag))
        .route("/bags/:id", get(get_bag).put(update_bag).delete(delete_bag))
}


// GET /bags
async fn list_bags(
    State(pool): State<PgPool>,
    auth: AuthUser,
) -> Result<Json<Vec<CoffeeBag>>> {
    let bags = sqlx::query_as!(
        CoffeeBag,
        r#"SELECT * FROM coffee_bags
        WHERE user_id = $1
        ORDER BY created_at DESC"#,
        auth.user_id
    )
    .fetch_all(&pool)
    .await?;

    Ok(Json(bags))
}


// POST /bags
async fn create_bag(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Json(body): Json<CreateCoffeeBag>,
) -> Result<Json<CoffeeBag>> {
    let bag = sqlx::query_as!(
    CoffeeBag,
    r#"INSERT INTO coffee_bags
       (user_id, roaster, roaster_origin_city, roaster_origin_country,
       origin_country, origin_region, roast_level, variety, process,
       taste_notes, bean_type, harvest_date, roast_date, caffeine_free,
       batch_id, status, favorite, rating, buy_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
               COALESCE($16, 'opened'), $17, $18, $19)
       RETURNING *"#,
    auth.user_id,
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
    body.status,
    body.favorite.unwrap_or(false),
    body.rating,
    body.buy_url,
    )
    .fetch_one(&pool)
    .await?;

    // Generate the hash using the assigned ID and update the row with the hash
    let bag_hash = make_bag_hash(body.roaster.as_deref(), bag.id);
    let bag = sqlx::query_as!(
        CoffeeBag,
        r#"UPDATE coffee_bags SET bag_hash = $2 WHERE id = $3 AND user_id = $1
        RETURNING *"#,
        auth.user_id,
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
    auth: AuthUser,
    Path(id): Path<i32>
) -> Result<Json<CoffeeBag>> {
    let bag: CoffeeBag = sqlx::query_as!(
        CoffeeBag,
        r#"SELECT * FROM coffee_bags WHERE id = $2 AND user_id = $1"#,
        auth.user_id, id,
    )
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound(format!("Bag {} not found", id)))?;

    Ok(Json(bag))

}

// PUT bags:id
async fn update_bag(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Path(id): Path<i32>,
    Json(body): Json<CreateCoffeeBag>,
) -> Result<Json<CoffeeBag>> {
    let bag: CoffeeBag = sqlx::query_as!(
        CoffeeBag,
        r#"UPDATE coffee_bags SET
            roaster = $2, roaster_origin_city = $3, roaster_origin_country = $4,
            origin_country = $5, origin_region = $6, variety = $7, process = $8,
            taste_notes = $9, bean_type = $10, roast_level = $11,
            harvest_date = $12, roast_date = $13,
            caffeine_free = $14, batch_id = $15,
            status = COALESCE($17, status), favorite = COALESCE($18, favorite),
            rating = $19, buy_url = $20
           WHERE id = $16 AND user_id = $1
           RETURNING *"#,
        auth.user_id,
        body.roaster, body.roaster_origin_city, body.roaster_origin_country,
        body.origin_country, body.origin_region, body.variety, body.process,
        body.taste_notes.as_deref(), body.bean_type, body.roast_level,
        body.harvest_date, body.roast_date,
        body.caffeine_free.unwrap_or(false), body.batch_id,
        id,
        body.status, body.favorite, body.rating, body.buy_url,
    )
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound(format!("Bag {} not found", id)))?;

    Ok(Json(bag))
}

async fn delete_bag(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Path(id): Path<i32>,
) -> Result<Json<serde_json::Value>> {
    let result: sqlx::postgres::PgQueryResult = sqlx::query!(
        "DELETE FROM coffee_bags WHERE id = $2 AND user_id = $1",
        auth.user_id, id
    )
    .execute(&pool)
    .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound(format!("Bag {} not found", id)));
    }

    Ok(Json(serde_json::json!({ "deleted": id })))
}
