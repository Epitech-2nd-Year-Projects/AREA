CREATE TABLE "triggers" (
                            "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                            "event_id" UUID NOT NULL,
                            "area_id" UUID NOT NULL,
                            "status" "trigger_status" NOT NULL DEFAULT 'pending',
                            "match_info" JSONB,
                            "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "uq_trigger" ON "triggers" ("event_id","area_id");
CREATE INDEX "triggers_index_event_id" ON "triggers" ("event_id");
CREATE INDEX "triggers_index_area_status" ON "triggers" ("area_id","status");

ALTER TABLE "triggers"
    ADD CONSTRAINT "fk_triggers_event"
        FOREIGN KEY ("event_id") REFERENCES "action_events"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "triggers"
    ADD CONSTRAINT "fk_triggers_area"
        FOREIGN KEY ("area_id") REFERENCES "areas"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
