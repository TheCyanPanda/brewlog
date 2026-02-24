mod db;
mod models;
mod error;
mod hash;
mod routes;
mod utils;

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

    // Read config from env
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set in .env");
    let host = std::env::var("SERVER_HOST").unwrap_or("0.0.0.0".into());
    let port = std::env::var("SERVER_PORT").unwrap_or("3000".into());

    info!("Connecting to database...");
    let pool = PgPoolOptions::new()  // Pool: Let's multiple requests use the DB simultaneously
        .max_connections(10)
        .connect(&database_url)
        .await?;

    info!("Running migrations...");
    sqlx::migrate!("./migrations").run(&pool).await?; // Read SQL Schema

    let app: Router = Router::new() // register routers
        .merge(routes::coffee_bags::router())
        .merge(routes::brews::router())
        .merge(routes::equipment::router())
        .merge(routes::export::router())
        .merge(routes::ha::router()) // Home assistant
        .layer(CorsLayer::permissive()) // Allow android app to connect
        .layer(TraceLayer::new_for_http())  // Log all requests
        .with_state(pool);  // Make available to handlers

    let addr: String = format!("{}:{}", host, port);
    info!("Brewlog server listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())


}




