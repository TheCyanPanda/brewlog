//   GET /bags/photos     - ids of the user's bags that have a photo
//   GET /bags/:id/photo  - the photo itself (raw image bytes)
//   PUT /bags/:id/photo  - set or replace the photo (raw image bytes, Content-Type header)
//
// Images are sent as raw bytes rather than base64 JSON, so no extra encoding is needed.

use axum::{
    Router, Json,
    body::Bytes,
    extract::{DefaultBodyLimit, Path, State},
    http::{header, HeaderMap, StatusCode},
    response::IntoResponse,
    routing::get,
};
use sqlx::PgPool;

use crate::auth::AuthUser;
use crate::error::{AppError, Result};

const MAX_PHOTO_BYTES: usize = 8 * 1024 * 1024;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/bags/photos", get(list_photo_ids))
        .route("/bags/:id/photo", get(get_photo).put(put_photo))
        .layer(DefaultBodyLimit::max(MAX_PHOTO_BYTES))
}

// GET /bags/photos
async fn list_photo_ids(
    State(pool): State<PgPool>,
    auth: AuthUser,
) -> Result<Json<Vec<i32>>> {
    let ids = sqlx::query_scalar!(
        r#"SELECT p.bag_id FROM bag_photos p
           JOIN coffee_bags b ON b.id = p.bag_id
           WHERE b.user_id = $1"#,
        auth.user_id
    )
    .fetch_all(&pool)
    .await?;

    Ok(Json(ids))
}

// GET /bags/:id/photo
async fn get_photo(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Path(id): Path<i32>,
) -> Result<impl IntoResponse> {
    let photo = sqlx::query!(
        r#"SELECT p.media_type, p.data FROM bag_photos p
           JOIN coffee_bags b ON b.id = p.bag_id
           WHERE p.bag_id = $1 AND b.user_id = $2"#,
        id,
        auth.user_id
    )
    .fetch_optional(&pool)
    .await?
    .ok_or(AppError::NotFound(format!("Bag {id} has no photo")))?;

    Ok(([(header::CONTENT_TYPE, photo.media_type)], photo.data))
}

// PUT /bags/:id/photo
async fn put_photo(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Path(id): Path<i32>,
    headers: HeaderMap,
    body: Bytes,
) -> Result<StatusCode> {
    let media_type = headers
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or_default()
        .to_string();
    if !matches!(media_type.as_str(), "image/jpeg" | "image/png" | "image/webp") {
        return Err(AppError::BadRequest(format!("Unsupported image type '{media_type}'")));
    }
    if body.is_empty() {
        return Err(AppError::BadRequest("Empty image".into()));
    }

    // Only for the user's own bags
    let saved = sqlx::query!(
        r#"INSERT INTO bag_photos (bag_id, media_type, data)
           SELECT id, $3, $4 FROM coffee_bags WHERE id = $1 AND user_id = $2
           ON CONFLICT (bag_id) DO UPDATE
               SET media_type = EXCLUDED.media_type, data = EXCLUDED.data, updated_at = now()"#,
        id,
        auth.user_id,
        media_type,
        body.as_ref()
    )
    .execute(&pool)
    .await?;

    if saved.rows_affected() == 0 {
        return Err(AppError::NotFound(format!("Bag {id} not found")));
    }
    Ok(StatusCode::NO_CONTENT)
}
