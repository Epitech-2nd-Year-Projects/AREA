use std::env;

#[derive(Clone, Debug)]
pub struct Config {
    pub database_url: String,
    pub jwt_secret: String,
    pub token_ttl_minutes: i64,
    pub refresh_ttl_days: i64,
    pub cookie_domain: Option<String>,
    pub cookie_secure: bool,
    pub port: u16,
    pub cors_allowed_origins: Option<Vec<String>>, // comma-separated list
    pub cors_allow_credentials: bool,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        let database_url = env::var("DATABASE_URL")?;
        let jwt_secret = env::var("JWT_SECRET")?;
        let token_ttl_minutes = env::var("TOKEN_TTL_MINUTES").ok().and_then(|v| v.parse().ok()).unwrap_or(15);
        let refresh_ttl_days = env::var("REFRESH_TTL_DAYS").ok().and_then(|v| v.parse().ok()).unwrap_or(7);
        let cookie_domain = env::var("COOKIE_DOMAIN").ok();
        let cookie_secure = env::var("COOKIE_SECURE").ok().map(|v| v == "1" || v.to_lowercase() == "true").unwrap_or(false);
        let port = env::var("PORT").ok().and_then(|v| v.parse().ok()).unwrap_or(8080);
        let cors_allowed_origins = env::var("CORS_ALLOWED_ORIGINS").ok()
            .map(|v| v.split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect::<Vec<_>>() )
            .filter(|v| !v.is_empty());
        let cors_allow_credentials = env::var("CORS_ALLOW_CREDENTIALS").ok()
            .map(|v| v == "1" || v.to_lowercase() == "true")
            .unwrap_or(false);

        Ok(Self { database_url, jwt_secret, token_ttl_minutes, refresh_ttl_days, cookie_domain, cookie_secure, port, cors_allowed_origins, cors_allow_credentials })
    }
}
