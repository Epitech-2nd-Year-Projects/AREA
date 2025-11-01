ALTER TABLE "sessions"
    ADD COLUMN IF NOT EXISTS "auth_provider" TEXT;

UPDATE "sessions"
SET "auth_provider" = 'password'
WHERE "auth_provider" IS NULL;
