ALTER TABLE "user_component_configs" DROP CONSTRAINT IF EXISTS "fk_component_configs_component";
ALTER TABLE "user_component_configs" DROP CONSTRAINT IF EXISTS "fk_component_configs_user";
DROP INDEX IF EXISTS "component_configs_index_is_active";
DROP INDEX IF EXISTS "component_configs_index_component";
DROP INDEX IF EXISTS "component_configs_index_user";
DROP TABLE IF EXISTS "user_component_configs";
