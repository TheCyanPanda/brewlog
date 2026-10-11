use axum::{
    Router,Json,
    extract::{Path, Query, State},
    routing::{get, post},
};
use sqlx::PgPool;

use crate::{
    error::{AppError, Result},
    hash::{make_brew_hash, next_brew_number},
    models::{Brew, BrewFilter, BrewResponse, CreateBrew},
};
use crate::auth::AuthUser;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/brews", get(list_brews).post(create_brew))
        .route("/brews/:id", get(get_brew).delete(delete_brew))
}

// /GET /brews
async fn list_brews(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Query(filter): Query<BrewFilter>,
) -> Result<Json<Vec<BrewResponse>>> {
    let limit: i64 = filter.limit.unwrap_or(20).min(500); // LIMIT pgsql clause
    let offset: i64 = filter.offset.unwrap_or(0);

    // TODO: Avoid copied 'order_by' etc in each query: Make a parameterized function for
    // fetching data (table_name, user_id, order_by, etc are parameters to the fn) - fetch_rows

    let brews: Vec<Brew> = match (filter.rating, filter.coffee_bag_id) {
        (Some(rating), Some(bag_id)) => sqlx::query_as!(
            Brew,
            r#"SELECT * FROM brews WHERE rating = $2 AND coffee_bag_id = $3 AND user_id = $1
               ORDER BY brew_datetime DESC LIMIT $4 OFFSET $5"#,
            auth.user_id, rating, bag_id, limit, offset
        ).fetch_all(&pool).await?,

        (Some(rating), None) => sqlx::query_as!(
            Brew,
            r#"SELECT * FROM brews WHERE rating = $2 AND user_id = $1
               ORDER BY brew_datetime DESC LIMIT $3 OFFSET $4"#,
            auth.user_id, rating, limit, offset
        ).fetch_all(&pool).await?,

        (None, Some(bag_id)) => sqlx::query_as!(
            Brew,
            r#"SELECT * FROM brews WHERE coffee_bag_id = $2 AND user_id = $1
               ORDER BY brew_datetime DESC LIMIT $3 OFFSET $4"#,
            auth.user_id, bag_id, limit, offset
        ).fetch_all(&pool).await?,

        (None, None) => sqlx::query_as!(
            Brew,
            r#"SELECT * FROM brews WHERE user_id = $1
               ORDER BY brew_datetime DESC LIMIT $2 OFFSET $3"#,
            auth.user_id, limit, offset
        ).fetch_all(&pool).await?,
    };

    let responses: Vec<BrewResponse> = brews.into_iter().map(Into::into).collect();
    Ok(Json(responses))
}


async fn get_brew(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Path(id): Path<i32>,
) -> Result<Json<BrewResponse>> {
    let brew: Brew = sqlx::query_as!(
        Brew,
        r#"SELECT * FROM brews WHERE id = $2 AND user_id = $1"#,
        auth.user_id, id
    )
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound(format!("Brew id={id} not found")))?;

    Ok(Json(brew.into()))
}


async fn create_brew(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Json(body): Json<CreateBrew>,
) -> Result<Json<BrewResponse>> {
    let brew_datetime = body.brew_datetime.unwrap_or_else(chrono::Utc::now);

    let brew: Brew = sqlx::query_as!(
        Brew,
        r#"INSERT INTO brews
            (user_id, coffee_bag_id, brew_datetime, grinder_id, grind_setting,
             brewer_id, filter_paper, coffee_grams, water_grams,
             water_temp_c, brew_time_secs, brew_steps, rating, review, notes, recipe_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
           RETURNING *"#,
        auth.user_id,
        body.coffee_bag_id,
        brew_datetime,
        body.grinder_id,
        body.grind_setting,
        body.brewer_id,
        body.filter_paper,
        body.coffee_grams,
        body.water_grams,
        body.water_temp_c,
        body.brew_time_secs,
        body.brew_steps,
        body.rating,
        body.review,
        body.notes,
        body.recipe_id,
    )
    .fetch_one(&pool)
    .await?;

    // Generate brew hash if this brew is linked to a bag
    let brew: Brew = match body.coffee_bag_id {
        None => brew,  // no bag linked, skip hash generation
        Some(bag_id) => {
            let bag_hash: Option<String> = sqlx::query_scalar!(
                "SELECT bag_hash FROM coffee_bags WHERE id = $1",
                bag_id
            )
            .fetch_optional(&pool)
            .await?
            .flatten();

            match bag_hash {
                None => brew,  // bag exists but has no hash yet, skip
                Some(hash) => {
                    let brew_num: i64 = next_brew_number(&pool, bag_id).await? - 1;
                    let brew_hash: String = make_brew_hash(&hash, brew_num);

                    sqlx::query_as!(
                        Brew,
                        r#"UPDATE brews SET brew_hash = $1 WHERE id = $2
                           RETURNING *"#,
                        brew_hash,
                        brew.id
                    )
                    .fetch_one(&pool)
                    .await?
                }
            }
        }
    };

    Ok(Json(brew.into()))
}


async fn delete_brew(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Path(id): Path<i32>,
) -> Result<Json<serde_json::Value>> {
    let result: sqlx::postgres::PgQueryResult = sqlx::query!(
        "DELETE FROM brews WHERE id = $2 AND user_id = $1",
        auth.user_id, id
    )
    .execute(&pool)
    .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound(format!("Brew {} not found", id)));
    }

    Ok(Json(serde_json::json!({ "deleted": id })))
}
