CREATE TABLE "action_sources" (
                                  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                                  "component_config_id" UUID NOT NULL,
                                  "mode" "source_mode" NOT NULL,
                                  "cursor" JSONB,
                                  "webhook_secret" VARCHAR(128),
                                  "webhook_url_path" VARCHAR(128),
                                  "schedule" VARCHAR(64),
                                  "is_active" BOOLEAN NOT NULL DEFAULT TRUE,
                                  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "uq_action_sources_webhook_path" ON "action_sources" ("webhook_url_path");
CREATE INDEX "action_sources_index_component_config" ON "action_sources" ("component_config_id");
CREATE INDEX "action_sources_index_mode" ON "action_sources" ("mode");
CREATE INDEX "action_sources_index_is_active" ON "action_sources" ("is_active");

ALTER TABLE "action_sources"
    ADD CONSTRAINT "fk_action_sources_component_config"
        FOREIGN KEY ("component_config_id") REFERENCES "user_component_configs"("id")
            ON DELETE NO ACTION ON UPDATE NO ACTION;
