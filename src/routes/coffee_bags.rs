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

