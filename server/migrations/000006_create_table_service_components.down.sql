ALTER TABLE "service_components" DROP CONSTRAINT IF EXISTS "fk_components_provider";
DROP INDEX IF EXISTS "service_components_index_enabled";
DROP INDEX IF EXISTS "service_components_index_provider";
DROP INDEX IF EXISTS "uq_service_component";
DROP TABLE IF EXISTS "service_components";
