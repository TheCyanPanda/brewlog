//   GET  /grinders          - list grinders
//   POST /grinders          - add a grinder
//   GET  /brewers           - list brewers
//   POST /brewers           - add a brewer
//   POST /grinders/:id/maintenance, /brewers/:id/maintenance - mark cleaned/descaled now

use axum::{
    Router,
    extract::{Path, State},
    routing::{get, post},
    Json
};
use sqlx::PgPool;

use crate::{
    error::{AppError, Result},
    models::{Brewer, CreateBrewer, CreateGrinder, Grinder, Maintenance}
};
use crate::auth::AuthUser;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/grinders", get(list_grinders).post(create_grinder)) // add GET and POST route
        .route("/brewers", get(list_brewers).post(create_brewer))
        .route("/grinders/:id/maintenance", post(grinder_maintenance))
        .route("/brewers/:id/maintenance", post(brewer_maintenance))
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
        r#"INSERT INTO grinders (user_id, name, notes, purchased_at)
        VALUES ($1, $2, $3, $4)
        RETURNING *"#,
        auth.user_id,
        body.name,
        body.notes,
        body.purchased_at,
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
        r#"INSERT INTO brewers (user_id, name, brew_method, brew_type, brand, model, notes, purchased_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
        "#,
        auth.user_id,
        body.name, body.brew_method, body.brew_type, body.brand, body.model, body.notes,
        body.purchased_at,
    )
    .fetch_one(&pool)
    .await?;
    Ok(Json(brewer))
}

// POST /grinders/:id/maintenance  {"action": "cleaned"}
async fn grinder_maintenance(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Path(id): Path<i32>,
    Json(body): Json<Maintenance>,
) -> Result<Json<Grinder>> {
    if body.action != "cleaned" {
        return Err(AppError::BadRequest(format!("Unknown grinder maintenance '{}'", body.action)));
    }
    let grinder = sqlx::query_as!(
        Grinder,
        r#"UPDATE grinders SET last_cleaned_at = now()
        WHERE id = $2 AND user_id = $1
        RETURNING *"#,
        auth.user_id, id
    )
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound(format!("Grinder {} not found", id)))?;
    Ok(Json(grinder))
}

// POST /brewers/:id/maintenance  {"action": "cleaned" | "descaled"}
async fn brewer_maintenance(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Path(id): Path<i32>,
    Json(body): Json<Maintenance>,
) -> Result<Json<Brewer>> {
    let (cleaned, descaled) = match body.action.as_str() {
        "cleaned" => (true, false),
        "descaled" => (false, true),
        other => return Err(AppError::BadRequest(format!("Unknown brewer maintenance '{}'", other))),
    };
    let brewer = sqlx::query_as!(
        Brewer,
        r#"UPDATE brewers SET
            last_cleaned_at  = CASE WHEN $3 THEN now() ELSE last_cleaned_at END,
            last_descaled_at = CASE WHEN $4 THEN now() ELSE last_descaled_at END
        WHERE id = $2 AND user_id = $1
        RETURNING *"#,
        auth.user_id, id, cleaned, descaled
    )
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound(format!("Brewer {} not found", id)))?;
    Ok(Json(brewer))
}
