ALTER TABLE "action_sources" DROP CONSTRAINT IF EXISTS "fk_action_sources_component_config";
DROP INDEX IF EXISTS "action_sources_index_is_active";
DROP INDEX IF EXISTS "action_sources_index_mode";
DROP INDEX IF EXISTS "action_sources_index_component_config";
DROP INDEX IF EXISTS "uq_action_sources_webhook_path";
DROP TABLE IF EXISTS "action_sources";
