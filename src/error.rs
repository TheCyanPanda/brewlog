use axum::{http::StatusCode, response::{IntoResponse, Response}, Json};
use serde_json::json;

pub type Result<T> = std::result::Result<T, AppError>;

pub enum AppError {
    Database(sqlx::Error),
    NotFound(String),
    BadRequest(String),
}

impl From<sqlx::Error> for AppError {
    fn from(e: sqlx::Error) -> Self {
        AppError::Database(e)
    }
}


impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AppError::Database(e) => {
                tracing::error!("Database error: {}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "Database error".to_string())
            }
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, msg),
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, msg),
        };

        (status, Json(json!({ "error": message }))).into_response()
    }
}




