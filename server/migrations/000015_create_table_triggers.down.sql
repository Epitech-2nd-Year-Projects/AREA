ALTER TABLE "triggers" DROP CONSTRAINT IF EXISTS "fk_triggers_area";
ALTER TABLE "triggers" DROP CONSTRAINT IF EXISTS "fk_triggers_event";
DROP INDEX IF EXISTS "triggers_index_area_status";
DROP INDEX IF EXISTS "triggers_index_event_id";
DROP INDEX IF EXISTS "uq_trigger";
DROP TABLE IF EXISTS "triggers";
