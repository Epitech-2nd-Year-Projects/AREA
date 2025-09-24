CREATE TABLE "area_conditions" (
                                   "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                                   "area_id" UUID NOT NULL,
                                   "expression" JSONB NOT NULL,
                                   "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   PRIMARY KEY ("id")
);
CREATE INDEX "area_conditions_index_area" ON "area_conditions" ("area_id");

ALTER TABLE "area_conditions"
    ADD CONSTRAINT "fk_area_conditions_area"
        FOREIGN KEY ("area_id") REFERENCES "areas"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
