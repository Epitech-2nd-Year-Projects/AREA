ALTER TABLE "delivery_logs" DROP CONSTRAINT IF EXISTS "fk_delivery_logs_job";
DROP INDEX IF EXISTS "delivery_logs_index_created_at";
DROP INDEX IF EXISTS "delivery_logs_index_job_id";
DROP TABLE IF EXISTS "delivery_logs";
