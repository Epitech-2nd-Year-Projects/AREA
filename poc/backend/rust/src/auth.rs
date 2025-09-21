use crate::config::Config;
use argon2::{Argon2, password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString}};
use chrono::{Utc, Duration};
use jsonwebtoken::{encode, Header, EncodingKey};
use rand::rngs::OsRng;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: Uuid,
    pub email: String,
    pub exp: usize,
    pub typ: String,
}

pub fn hash_password(password: &str) -> anyhow::Result<String> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let hash = argon2
        .hash_password(password.as_bytes(), &salt)
        .map_err(|e| anyhow::anyhow!(e.to_string()))?
        .to_string();
    Ok(hash)
}

pub fn verify_password(password: &str, password_hash: &str) -> bool {
    let parsed = PasswordHash::new(password_hash);
    match parsed {
        Ok(ph) => Argon2::default().verify_password(password.as_bytes(), &ph).is_ok()
        ,
        Err(_) => false,
    }
}

pub fn create_access_token(cfg: &Config, user_id: Uuid, email: &str) -> anyhow::Result<String> {
    let exp = Utc::now() + Duration::minutes(cfg.token_ttl_minutes);
    let claims = Claims { sub: user_id, email: email.to_string(), exp: exp.timestamp() as usize, typ: "access".into() };
    let token = encode(&Header::default(), &claims, &EncodingKey::from_secret(cfg.jwt_secret.as_bytes()))?;
    Ok(token)
}

pub fn create_refresh_token(cfg: &Config, user_id: Uuid, email: &str) -> anyhow::Result<String> {
    let exp = Utc::now() + Duration::days(cfg.refresh_ttl_days);
    let claims = Claims { sub: user_id, email: email.to_string(), exp: exp.timestamp() as usize, typ: "refresh".into() };
    let token = encode(&Header::default(), &claims, &EncodingKey::from_secret(cfg.jwt_secret.as_bytes()))?;
    Ok(token)
}
