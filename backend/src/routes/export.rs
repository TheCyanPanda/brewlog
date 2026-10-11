use axum::{
    extract::{Path, State},
    routing::get,
    Json,
    Router,
};
use sqlx::PgPool;

use crate::{
    db::{all_brews_export, grind_analytics, BrewExport, GrindDataPoint},
    error::Result,
};
use crate::auth::AuthUser;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/export/brews", get(export_brews))
        .route("/analytics/grind/:bag_id", get(grind_data))
}

async fn export_brews(
    State(pool): State<PgPool>,
    auth: AuthUser,
) -> Result<Json<Vec<BrewExport>>> {
    let rows: Vec<BrewExport> = all_brews_export(&pool, auth.user_id).await?;
    Ok(Json(rows))
}

async fn grind_data(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Path(bag_id): Path<i32>,
) -> Result<Json<Vec<GrindDataPoint>>> {
    let points: Vec<GrindDataPoint> = grind_analytics(&pool, auth.user_id, bag_id).await?;
    Ok(Json(points))
}
