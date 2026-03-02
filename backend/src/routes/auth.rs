use argon2::{Argon2, password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString}};
use axum::{extract::State, http::HeaderMap, routing::post, Json, Router};
use sha2::{Digest, Sha256};
use sqlx::PgPool;
use tracing::info;

use crate::{
    error::{AppError, Result},
    models::{CreateUser, LoginRequest, LoginResponse, User}
};

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/auth/register", post(register))
        .route("/auth/login", post(login))
        .route("/auth/logout", post(logout))
}

// Hash a plain text password with argon2id, returns the full PHC string
fn hash_password(pwd: &str) -> Result<String> {
    let salt = SaltString::generate(&mut OsRng);
    let hash = Argon2::default()
        .hash_password(pwd.as_bytes(), &salt)
        .map_err(|_| AppError::BadRequest("Failed to hash password".into()))?
        .to_string();
    Ok(hash)
}

// Verify plain text password against a stored argon2 PHC hash
fn verify_password(pwd: &str, hash: &str) -> bool {
    let Ok(parsed) = PasswordHash::new(hash) else {return false;};
    Argon2::default().verify_password(pwd.as_bytes(), &parsed).is_ok()
}

// Generate a crypty 32b token, hex encoded (64 chars). This raw value os returned only to client
// (never stored)
fn generate_token() -> String {
    let bytes: [u8; 32] = rand::random();
    hex::encode(bytes)
}

// SHA256 of the raw token (This is what we store in the DB)
fn hash_token(token: &str) -> String {
    hex::encode(Sha256::digest(token.as_bytes()))
}

// Pull the raw token out of "Authorization: Bearer <token>"
fn extract_bearer_token(headers: &HeaderMap) -> Option<String> {
    headers.get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .map(|s| s.to_string())
}

// /POST /auth/register
async fn register(
    State(pool): State<PgPool>,
    Json(body): Json<CreateUser>,
) -> Result<Json<User>> {
    info!("registering user: {}", body.username);
    let hash = hash_password(&body.password)?;
    let user = sqlx::query_as!(
        User,
        r#"INSERT INTO users (username, display_name, email, password_hash)
           VALUES ($1, $2, $3, $4)
           RETURNING *"#,
        body.username,
        body.display_name,
        body.email,
        hash
    )
    .fetch_one(&pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::Database(ref db) if db.constraint() == Some ("users_username_key") => {
            AppError::BadRequest("Username already taken".into())
        }
        _ => AppError::from(e),
    })?;

    Ok(Json(user))
}


// POST /auth/login
// Verifies credentials, issues a bearer token.
// Return 401 for wrong username OR wrong password to void leaking which usernames exist
async fn login(
    State(pool): State<PgPool>,
    Json(body): Json<LoginRequest>,
) -> Result<Json<LoginResponse>> {
    let user: Option<User> = sqlx::query_as!(
        User,
        "SELECT * FROM users WHERE username = $1",
        body.username,
    )
    .fetch_optional(&pool)
    .await?;

    if user.is_some() {
        info!("User: '{}' - Attempting login", body.username);
    }

    // Verify password: if user not found OR password wrong, same error
    let user = user
        .filter(|u| verify_password(&body.password, &u.password_hash))
        .ok_or(AppError::Unauthorized)?;

    // Generate token, store its hash in the DB
    let raw_token = generate_token();
    let token_hash = hash_token(&raw_token);

    sqlx::query!(
        "INSERT INTO user_tokens (user_id, token_hash, label) VALUES ($1, $2, $3)",
        user.id,
        token_hash,
        "mobile",
    )
    .execute(&pool)
    .await?;

    let res = Ok(Json(LoginResponse {
        token: raw_token,   // raw token — only time it leaves the server
        user_id: user.id,
        username: user.username.clone(),
    }));
    if res.is_ok() {
        info!("User: '{}' - Login successful", body.username);
    }
    res
}

// POST /auth/logout
// Deletes the token from the DB, revokes it on the server
async fn logout(
    State(pool): State<PgPool>,
    headers: HeaderMap,
) -> Result<Json<serde_json::Value>> {
    let token = extract_bearer_token(&headers).ok_or(AppError::Unauthorized)?;
    let token_hash = hash_token(&token);

    sqlx::query!(
        "DELETE FROM user_tokens WHERE token_hash = $1",
        token_hash
    )
    .execute(&pool)
    .await?;

    Ok(Json(serde_json::json!({ "message": "Logged out" })))
}

// TODO: Add delete user function

