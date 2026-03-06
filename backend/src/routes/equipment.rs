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
use crate::auth::AuthUser;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/grinders", get(list_grinders).post(create_grinder)) // add GET and POST route
        .route("/brewers", get(list_brewers).post(create_brewer))
}

// GET /grinders
async fn list_grinders(
    State(pool): State<PgPool>,
    auth: AuthUser,
) -> Result<Json<Vec<Grinder>>> {
    let grinders = sqlx::query_as!(
        Grinder,
        r#"SELECT * FROM grinders
            WHERE user_id = $1
            ORDER BY name"#,
        auth.user_id
    )
    .fetch_all(&pool)
    .await?;
    Ok(Json(grinders))
}

// /POST /grinders
async fn create_grinder(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Json(body): Json<CreateGrinder>
) -> Result<Json<Grinder>> {
    let grinder = sqlx::query_as!(
        Grinder,
        r#"INSERT INTO grinders (user_id, name, notes)
        VALUES ($1, $2, $3)
        RETURNING *"#,
        auth.user_id,
        body.name,
        body.notes
    )
    .fetch_one(&pool)
    .await?;
    Ok(Json(grinder))
}

async fn list_brewers(
    State(pool): State<PgPool>,
    auth: AuthUser,
) -> Result<Json<Vec<Brewer>>> {
    let brewer = sqlx::query_as!(
        Brewer,
        r#"SELECT * FROM brewers
        WHERE user_id = $1
        ORDER BY name"#,
        auth.user_id,
    )
    .fetch_all(&pool)
    .await?;
    Ok(Json(brewer))
}

async fn create_brewer(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Json(body): Json<CreateBrewer>
) -> Result<Json<Brewer>> {
    let brewer = sqlx::query_as!(
        Brewer,
        r#"INSERT INTO brewers (user_id, name, brew_method, brew_type, brand, model, notes)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *
        "#,
        auth.user_id,
        body.name, body.brew_method, body.brew_type, body.brand, body.model, body.notes
    )
    .fetch_one(&pool)
    .await?;
    Ok(Json(brewer))
}
