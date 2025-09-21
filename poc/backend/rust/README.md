**Rust Backend Summary**

**Highlights**
- Straightforward routing and JSON with `axum` + `serde`.
- Unified error handling via `thiserror` + `IntoResponse`.
- Simple auth primitives: Argon2 hashing and JWT issuance.
- Easy DB setup: pooled Postgres and `sqlx::migrate!`.

**Challenges**
- Async/borrowing quirks with `sqlx` mutable connections.
- CORS/cookie settings for cross-origin auth are subtle.
- `sqlx` features/metadata and crate versions add setup friction.

**Runtime**
- Fast and memory‑efficient; strong typing catches issues early.
- Small pool (`max_connections(5)`) stays responsive for simple queries.

**Dev Notes**
- Works with `.env` (`DATABASE_URL`, `JWT_SECRET`, …).
- Consider adding request/response tests and basic spans.

**Bottom Line**
- Axum + SQLx delivers a lean, safe backend with great runtime performance once initial setup details are settled.
