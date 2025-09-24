ALTER TABLE "area_conditions" DROP CONSTRAINT IF EXISTS "fk_area_conditions_area";
DROP INDEX IF EXISTS "area_conditions_index_area";
DROP TABLE IF EXISTS "area_conditions";
