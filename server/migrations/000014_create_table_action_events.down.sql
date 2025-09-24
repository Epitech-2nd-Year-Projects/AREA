ALTER TABLE "action_events" DROP CONSTRAINT IF EXISTS "fk_action_events_source";
DROP INDEX IF EXISTS "action_events_index_dedup";
DROP INDEX IF EXISTS "action_events_index_source_time";
DROP INDEX IF EXISTS "uq_action_event";
DROP TABLE IF EXISTS "action_events";
