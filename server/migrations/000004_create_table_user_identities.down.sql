ALTER TABLE "user_identities" DROP CONSTRAINT IF EXISTS "fk_user_identities_provider_name";
ALTER TABLE "user_identities" DROP CONSTRAINT IF EXISTS "fk_user_identities_user";
DROP INDEX IF EXISTS "uq_user_identities_provider_subject";
DROP INDEX IF EXISTS "user_identities_index_provider";
DROP INDEX IF EXISTS "user_identities_index_user_id";
DROP TABLE IF EXISTS "user_identities";
