use axum::{http::StatusCode, response::{IntoResponse, Response}, Json};
use serde::Serialize;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ApiError {
    #[error("bad request: {0}")]
    BadRequest(String),
    #[error("unauthorized")]
    Unauthorized,
    #[error("conflict: {0}")]
    Conflict(String),
    #[error(transparent)]
    Sqlx(#[from] sqlx::Error),
    #[error(transparent)]
    Anyhow(#[from] anyhow::Error),
}

#[derive(Serialize)]
struct ErrorBody {
    error: String,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, msg) = match &self {
            ApiError::BadRequest(m) => (StatusCode::BAD_REQUEST, m.clone()),
            ApiError::Unauthorized => (StatusCode::UNAUTHORIZED, "unauthorized".into()),
            ApiError::Conflict(m) => (StatusCode::CONFLICT, m.clone()),
            ApiError::Sqlx(_) | ApiError::Anyhow(_) => (StatusCode::INTERNAL_SERVER_ERROR, "internal error".into()),
        };
        (status, Json(ErrorBody { error: msg })).into_response()
    }
}

pub type ApiResult<T> = Result<T, ApiError>;

