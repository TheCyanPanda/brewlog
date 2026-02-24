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

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/export/brews", get(export_brews))
        .route("/analytics/grind/:bag_id", get(grind_data))
}

async fn export_brews(State(pool): State<PgPool>) -> Result<Json<Vec<BrewExport>>> {
    let rows: Vec<BrewExport> = all_brews_export(&pool).await?;
    Ok(Json(rows))
}

async fn grind_data(
    State(pool): State<PgPool>,
    Path(bag_id): Path<i32>,
) -> Result<Json<Vec<GrindDataPoint>>> {
    let points: Vec<GrindDataPoint> = grind_analytics(&pool, bag_id).await?;
    Ok(Json(points))
}
