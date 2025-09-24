CREATE TABLE "area_links" (
                              "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                              "area_id" UUID NOT NULL,
                              "role" "link_role" NOT NULL,
                              "component_config_id" UUID NOT NULL,
                              "position" INT NOT NULL DEFAULT 1,
                              "retry_policy" JSONB,
                              "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              PRIMARY KEY ("id")
);
CREATE INDEX "area_links_index_area_role" ON "area_links" ("area_id","role");
CREATE INDEX "area_links_index_component_config" ON "area_links" ("component_config_id");
CREATE INDEX "area_links_index_order" ON "area_links" ("area_id","role","position");
CREATE UNIQUE INDEX "uq_area_links_single_action" ON "area_links" ("area_id");

ALTER TABLE "area_links"
    ADD CONSTRAINT "fk_area_links_area"
        FOREIGN KEY ("area_id") REFERENCES "areas"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "area_links"
    ADD CONSTRAINT "fk_area_links_component_config"
        FOREIGN KEY ("component_config_id") REFERENCES "user_component_configs"("id")
            ON DELETE NO ACTION ON UPDATE NO ACTION;
