ALTER TABLE "jobs" DROP CONSTRAINT IF EXISTS "fk_jobs_area_link";
ALTER TABLE "jobs" DROP CONSTRAINT IF EXISTS "fk_jobs_trigger";
DROP INDEX IF EXISTS "jobs_index_area_link";
DROP INDEX IF EXISTS "jobs_index_trigger";
DROP INDEX IF EXISTS "jobs_index_lock";
DROP INDEX IF EXISTS "jobs_index_status_run_at";
DROP TABLE IF EXISTS "jobs";
