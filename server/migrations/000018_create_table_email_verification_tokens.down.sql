ALTER TABLE "email_verification_tokens"
    DROP CONSTRAINT IF EXISTS "fk_email_verification_tokens_user";

DROP INDEX IF EXISTS "email_verification_tokens_index_expires_at";
DROP INDEX IF EXISTS "email_verification_tokens_index_user_id";
DROP INDEX IF EXISTS "uq_email_verification_tokens_token";

DROP TABLE IF EXISTS "email_verification_tokens";
