CREATE TABLE "jobs" (
                        "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                        "trigger_id" UUID NOT NULL,
                        "area_link_id" UUID NOT NULL,
                        "status" "job_status" NOT NULL DEFAULT 'queued',
                        "attempt" INT NOT NULL DEFAULT 0,
                        "run_at" TIMESTAMPTZ NOT NULL,
                        "locked_by" VARCHAR(64),
                        "locked_at" TIMESTAMPTZ,
                        "input_payload" JSONB,
                        "result_payload" JSONB,
                        "error" TEXT,
                        "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        PRIMARY KEY ("id")
);
CREATE INDEX "jobs_index_status_run_at" ON "jobs" ("status","run_at");
CREATE INDEX "jobs_index_lock" ON "jobs" ("locked_by","locked_at");
CREATE INDEX "jobs_index_trigger" ON "jobs" ("trigger_id");
CREATE INDEX "jobs_index_area_link" ON "jobs" ("area_link_id");

ALTER TABLE "jobs"
    ADD CONSTRAINT "fk_jobs_trigger"
        FOREIGN KEY ("trigger_id") REFERENCES "triggers"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "jobs"
    ADD CONSTRAINT "fk_jobs_area_link"
        FOREIGN KEY ("area_link_id") REFERENCES "area_links"("id")
            ON DELETE NO ACTION ON UPDATE NO ACTION;
