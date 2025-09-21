mod config;
mod db;
mod auth;
mod routes;
mod error;

use axum::{Router, routing::post};
use tower_cookies::CookieManagerLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use tower_http::cors::{CorsLayer, Any};
use axum::http::{HeaderValue, Method, header};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();

    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let cfg = config::Config::from_env()?;
    let pool = db::init_pool(&cfg.database_url).await?;
    db::run_migrations(&pool).await?;

    let state = routes::AppState::new(pool, cfg.clone());

    // Configure CORS
    let cors = match &cfg.cors_allowed_origins {
        Some(origins) if !origins.is_empty() => {
            let allowed_origins: Vec<HeaderValue> = origins
                .iter()
                .filter_map(|o| o.parse().ok())
                .collect();

            let mut layer = CorsLayer::new()
                .allow_origin(allowed_origins)
                .allow_methods([
                    Method::GET,
                    Method::POST,
                    Method::PUT,
                    Method::PATCH,
                    Method::DELETE,
                    Method::OPTIONS,
                ])
                .allow_headers([header::ACCEPT, header::AUTHORIZATION, header::CONTENT_TYPE]);

            if cfg.cors_allow_credentials {
                layer = layer.allow_credentials(true);
            }

            layer
        }
        _ => {
            // Development-friendly default: permissive CORS
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any)
        }
    };

    let app = Router::new()
        .route("/register", post(routes::register))
        .route("/auth", post(routes::auth))
        .with_state(state)
        .layer(cors)
        .layer(CookieManagerLayer::new());

    let addr = std::net::SocketAddr::from(([0, 0, 0, 0], cfg.port));
    tracing::info!("listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
