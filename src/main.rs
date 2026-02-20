mod db;
mod models;
mod error;
mod hash;
mod routes;

use axum::Router;
use sqlx::postgres::PgPoolOptions;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;
use tracing::info;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok(); // Load .env file

    tracing_subscriber::registry() // Initialize logging
        .with(tracing_subscriber::EnvFilter::try_from_default_env()  // env var: RUST_LOG=debug
            .unwrap_or_else(|_| "brewlog=debug,tower_http=info".into()))  // fallback if unset
        .with(tracing_subscriber::fmt::layer())
        .init();

    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set in .env");
    let host = std::env::var("SERVER_HOST").unwrap_or("0.0.0.0".into());
    let port = std::env::var("SERVER_PORT").unwrap_or("3000".into());

    info!("Connecting to database...");
    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await?;

    info!("Running migrations...");
    sqlx::migrate!("./migrations").run(&pool).await?; // Read SQL Schema

    let app: Router = Router::new()
        .merge(routes::coffee_bags::router())
        .merge(routes::brews::router())
        .merge(routes::equipment::router())
        .merge(routes::ha::router())
        .layer(CorsLayer::permissive())
        .layer(TraceLayer::new_for_http())
        .with_state(pool);

    Ok(())


}




