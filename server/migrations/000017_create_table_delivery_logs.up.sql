CREATE TABLE "delivery_logs" (
                                 "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                                 "job_id" UUID NOT NULL,
                                 "endpoint" TEXT NOT NULL,
                                 "request" JSONB NOT NULL,
                                 "response" JSONB,
                                 "status_code" INT,
                                 "duration_ms" INT,
                                 "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 PRIMARY KEY ("id")
);
CREATE INDEX "delivery_logs_index_job_id" ON "delivery_logs" ("job_id");
CREATE INDEX "delivery_logs_index_created_at" ON "delivery_logs" ("created_at");

ALTER TABLE "delivery_logs"
    ADD CONSTRAINT "fk_delivery_logs_job"
        FOREIGN KEY ("job_id") REFERENCES "jobs"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
