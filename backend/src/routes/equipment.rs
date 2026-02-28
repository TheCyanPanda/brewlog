//   GET  /grinders          - list grinders
//   POST /grinders          - add a grinder
//   GET  /brewers           - list brewers
//   POST /brewers           - add a brewer

use axum::{
    Router,
    extract::State,
    routing::{get, post},
    Json
};
use sqlx::PgPool;

use crate::{
    error::Result,
    models::{Brewer, CreateBrewer, CreateGrinder, Grinder}
};

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/grinders", get(list_grinders).post(create_grinder)) // add GET and POST route
        .route("/brewers", get(list_brewers).post(create_brewer))
}

async fn list_grinders(State(pool): State<PgPool>) -> Result<Json<Vec<Grinder>>> {
    let grinders = sqlx::query_as!(
        Grinder,
        "SELECT * FROM grinders ORDER BY name",
    )
    .fetch_all(&pool)
    .await?;
    Ok(Json(grinders))
}

async fn create_grinder(
    State(pool): State<PgPool>,
    Json(body): Json<CreateGrinder>
) -> Result<Json<Grinder>> {
    let grinder = sqlx::query_as!(
        Grinder,
        r#"INSERT INTO grinders (name, notes)
        VALUES ($1, $2)
        RETURNING *"#,
        body.name,
        body.notes
    )
    .fetch_one(&pool)
    .await?;
    Ok(Json(grinder))
}

async fn list_brewers(State(pool): State<PgPool>) -> Result<Json<Vec<Brewer>>> {
    let brewer = sqlx::query_as!(
        Brewer,
        "SELECT * FROM brewers ORDER BY name"
    )
    .fetch_all(&pool)
    .await?;
    Ok(Json(brewer))
}

async fn create_brewer(
    State(pool): State<PgPool>,
    Json(body): Json<CreateBrewer>
) -> Result<Json<Brewer>> {
    let brewer = sqlx::query_as!(
        Brewer,
        r#"INSERT INTO brewers (name, brew_method, brew_type, brand, model, notes)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
        "#,
        body.name, body.brew_method, body.brew_type, body.brand, body.model, body.notes
    )
    .fetch_one(&pool)
    .await?;
    Ok(Json(brewer))
}
