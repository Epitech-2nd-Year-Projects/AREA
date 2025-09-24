CREATE TABLE "user_component_configs" (
                                          "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                                          "user_id" UUID NOT NULL,
                                          "component_id" UUID NOT NULL,
                                          "name" VARCHAR(128),
                                          "params" JSONB NOT NULL,
                                          "secrets_ref" VARCHAR(128),
                                          "is_active" BOOLEAN NOT NULL DEFAULT TRUE,
                                          "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                          "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                          PRIMARY KEY ("id")
);
CREATE INDEX "component_configs_index_user" ON "user_component_configs" ("user_id");
CREATE INDEX "component_configs_index_component" ON "user_component_configs" ("component_id");
CREATE INDEX "component_configs_index_is_active" ON "user_component_configs" ("is_active");

ALTER TABLE "user_component_configs"
    ADD CONSTRAINT "fk_component_configs_user"
        FOREIGN KEY ("user_id") REFERENCES "users"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "user_component_configs"
    ADD CONSTRAINT "fk_component_configs_component"
        FOREIGN KEY ("component_id") REFERENCES "service_components"("id")
            ON DELETE NO ACTION ON UPDATE NO ACTION;
