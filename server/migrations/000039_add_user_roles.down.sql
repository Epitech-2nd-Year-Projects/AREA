DROP INDEX IF EXISTS "users_index_role";
ALTER TABLE "users" DROP COLUMN IF EXISTS "role";
DROP TYPE IF EXISTS "user_role";
