ALTER TABLE "areas" DROP CONSTRAINT IF EXISTS "fk_areas_user";
DROP INDEX IF EXISTS "areas_index_status";
DROP INDEX IF EXISTS "areas_index_user_id";
DROP TABLE IF EXISTS "areas";
