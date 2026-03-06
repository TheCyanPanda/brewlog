use axum::{
    async_trait,
    extract::FromRequestParts,
    http::{request::Parts, StatusCode},
    response::{IntoResponse, Response},
    Json
};

use serde_json::json;
use sha2::{Digest, Sha256};
use sqlx::PgPool;

// Auth context that is injected into handlers that required a logged in user.
pub struct AuthUser {
    pub user_id: i32,
}

pub enum AuthError {
    MissingToken,
    InvalidToken,
    DatabaseError
}

impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        let message = match self {
            AuthError::MissingToken => "Missing authorization token",
            AuthError::InvalidToken => "Invalid or expired token",
            AuthError::DatabaseError => "Internal server error",
        };
        (StatusCode::UNAUTHORIZED, Json(json!({"error": message}))).into_response()
    }
}


//FromRequestParts lets us extract data from the request before the body is consumed
#[async_trait]
impl FromRequestParts<PgPool> for AuthUser {
    type Rejection = AuthError;

    async fn from_request_parts(
        parts: &mut Parts,
        pool: &PgPool,
    ) -> Result<Self, Self::Rejection> {
        // Extract 'Authorization: Bearer <token>'
        let token = parts.headers
            .get("Authorization")
            .and_then(|v| v.to_str().ok())
            .and_then(|s| s.strip_prefix("Bearer "))
            .ok_or(AuthError::MissingToken)?;

        // Hash the row token to look it up in the DB
        let token_hash = hex::encode(Sha256::digest(token.as_bytes()));

        // TODO: Make this into a function
        // Look up the token
        let user_id: Option<i32> = sqlx::query_scalar!(
            r#"SELECT user_id FROM user_tokens
               WHERE token_hash = $1
               AND (expires_at IS NULL OR expires_at > now())"#,
            token_hash
        )
        .fetch_optional(pool)
        .await
        .map_err(|_| AuthError::DatabaseError)?;

        let user_id = user_id.ok_or(AuthError::InvalidToken)?;
        Ok(AuthUser{user_id})
    }
}
