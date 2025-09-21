use crate::{db::PgPool, config::Config, error::{ApiError, ApiResult}, auth};
use axum::{extract::State, Json};
use serde::{Deserialize, Serialize};
use sqlx::Row;
use tower_cookies::{Cookie, Cookies};
use tower_cookies::cookie::SameSite;
use tower_cookies::cookie::time::Duration as CookieDuration;
use uuid::Uuid;

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub cfg: Config,
}

impl AppState {
    pub fn new(pool: PgPool, cfg: Config) -> Self { Self { pool, cfg } }
}

#[derive(Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
}

#[derive(Serialize)]
pub struct RegisterResponse {
    pub id: Uuid,
    pub email: String,
}

#[derive(Deserialize)]
pub struct AuthRequest {
    pub email: String,
    pub password: String,
}

#[derive(Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
}

pub async fn register(State(state): State<AppState>, cookies: Cookies, Json(payload): Json<RegisterRequest>) -> ApiResult<Json<RegisterResponse>> {
    if payload.password.len() < 8 {
        return Err(ApiError::BadRequest("password must be at least 8 characters".into()));
    }
    if !payload.email.contains('@') {
        return Err(ApiError::BadRequest("invalid email".into()));
    }

    let mut conn = state.pool.acquire().await?;
    let user_id = Uuid::new_v4();
    let password_hash = auth::hash_password(&payload.password)?;

    let res = sqlx::query(
        "INSERT INTO users (id, email, password_hash) VALUES ($1, $2, $3)"
    )
        .bind(user_id)
        .bind(&payload.email)
        .bind(&password_hash)
        .execute(&mut *conn)
        .await;

    match res {
        Ok(_) => {
            let access = auth::create_access_token(&state.cfg, user_id, &payload.email)?;
            let refresh = auth::create_refresh_token(&state.cfg, user_id, &payload.email)?;
            set_auth_cookies(&state.cfg, &cookies, &access, &refresh);
            Ok(Json(RegisterResponse { id: user_id, email: payload.email }))
        }
        Err(e) => {
            if let sqlx::Error::Database(db_err) = &e {
                if db_err.constraint() == Some("users_email_key") {
                    return Err(ApiError::Conflict("email already registered".into()));
                }
            }
            Err(ApiError::Sqlx(e))
        }
    }
}

pub async fn auth(State(state): State<AppState>, cookies: Cookies, Json(payload): Json<AuthRequest>) -> ApiResult<Json<AuthResponse>> {
    let rec = sqlx::query(
        "SELECT id, email, password_hash FROM users WHERE email = $1"
    )
    .bind(&payload.email)
    .fetch_optional(&state.pool)
    .await?;

    let rec = match rec { Some(r) => r, None => return Err(ApiError::Unauthorized) };

    let id: Uuid = rec.get("id");
    let email: String = rec.get::<String, _>("email");
    let password_hash: String = rec.get::<String, _>("password_hash");

    if !auth::verify_password(&payload.password, &password_hash) {
        return Err(ApiError::Unauthorized);
    }

    let access = auth::create_access_token(&state.cfg, id, &email)?;
    let refresh = auth::create_refresh_token(&state.cfg, id, &email)?;
    set_auth_cookies(&state.cfg, &cookies, &access, &refresh);

    Ok(Json(AuthResponse { access_token: access, refresh_token: refresh }))
}

fn set_auth_cookies(cfg: &Config, cookies: &Cookies, access: &str, refresh: &str) {
    let access_age = CookieDuration::seconds((cfg.token_ttl_minutes * 60) as i64);
    let refresh_age = CookieDuration::seconds((cfg.refresh_ttl_days * 24 * 3600) as i64);

    let mut token_builder = Cookie::build(("token", access.to_owned()))
        .http_only(true)
        .same_site(SameSite::Lax)
        .path("/")
        .max_age(access_age)
        .secure(cfg.cookie_secure);

    if let Some(domain) = &cfg.cookie_domain { token_builder = token_builder.domain(domain.clone()); }
    let token_cookie = token_builder.build();

    let mut refresh_builder = Cookie::build(("refresh_token", refresh.to_owned()))
        .http_only(true)
        .same_site(SameSite::Lax)
        .path("/")
        .max_age(refresh_age)
        .secure(cfg.cookie_secure);

    if let Some(domain) = &cfg.cookie_domain { refresh_builder = refresh_builder.domain(domain.clone()); }
    let refresh_cookie = refresh_builder.build();

    cookies.add(token_cookie);
    cookies.add(refresh_cookie);
}
