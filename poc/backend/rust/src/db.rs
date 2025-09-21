use sqlx::{Pool, Postgres};

pub type PgPool = Pool<Postgres>;

pub async fn init_pool(database_url: &str) -> anyhow::Result<PgPool> {
    let pool = sqlx::postgres::PgPoolOptions::new()
        .max_connections(5)
        .connect(database_url)
        .await?;
    Ok(pool)
}

pub async fn run_migrations(pool: &PgPool) -> anyhow::Result<()> {
    // This expects a `migrations` directory at project root
    sqlx::migrate!("./migrations").run(pool).await?;
    Ok(())
}

