CREATE TABLE "service_components" (
                                      "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                                      "provider_id" UUID NOT NULL,
                                      "kind" "component_kind" NOT NULL,
                                      "name" VARCHAR(64) NOT NULL,
                                      "display_name" VARCHAR(128) NOT NULL,
                                      "description" TEXT,
                                      "version" INT NOT NULL DEFAULT 1,
                                      "input_schema" JSONB,
                                      "output_schema" JSONB,
                                      "metadata" JSONB,
                                      "is_enabled" BOOLEAN NOT NULL DEFAULT TRUE,
                                      "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                      "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                      PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "uq_service_component"
    ON "service_components" ("provider_id","kind","name","version");
CREATE INDEX "service_components_index_provider" ON "service_components" ("provider_id");
CREATE INDEX "service_components_index_enabled" ON "service_components" ("provider_id","kind","name");

ALTER TABLE "service_components"
    ADD CONSTRAINT "fk_components_provider"
        FOREIGN KEY ("provider_id") REFERENCES "service_providers"("id")
            ON DELETE NO ACTION ON UPDATE NO ACTION;
