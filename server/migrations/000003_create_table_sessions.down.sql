ALTER TABLE "sessions" DROP CONSTRAINT IF EXISTS "fk_sessions_user";
DROP INDEX IF EXISTS "sessions_index_revoked_at";
DROP INDEX IF EXISTS "sessions_index_expires_at";
DROP INDEX IF EXISTS "sessions_index_user_id";
DROP TABLE IF EXISTS "sessions";
