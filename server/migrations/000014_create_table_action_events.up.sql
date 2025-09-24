CREATE TABLE "action_events" (
                                 "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                                 "source_id" UUID NOT NULL,
                                 "occurred_at" TIMESTAMPTZ NOT NULL,
                                 "received_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 "fingerprint" TEXT NOT NULL,
                                 "payload" JSONB NOT NULL,
                                 "dedup_status" "dedup_status" NOT NULL DEFAULT 'new',
                                 PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "uq_action_event" ON "action_events" ("source_id","fingerprint");
CREATE INDEX "action_events_index_source_time" ON "action_events" ("source_id","occurred_at");
CREATE INDEX "action_events_index_dedup" ON "action_events" ("dedup_status");

ALTER TABLE "action_events"
    ADD CONSTRAINT "fk_action_events_source"
        FOREIGN KEY ("source_id") REFERENCES "action_sources"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
