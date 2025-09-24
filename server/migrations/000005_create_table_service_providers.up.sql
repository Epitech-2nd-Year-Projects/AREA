CREATE TABLE "service_providers" (
                                     "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                                     "name" VARCHAR(64) NOT NULL,
                                     "display_name" VARCHAR(128) NOT NULL,
                                     "category" VARCHAR(64),
                                     "oauth_type" "auth_kind" NOT NULL,
                                     "auth_config" JSONB,
                                     "is_enabled" BOOLEAN NOT NULL DEFAULT TRUE,
                                     "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                     "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                     PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "uq_service_providers_name" ON "service_providers" ("name");
CREATE INDEX "service_providers_index_enabled_name" ON "service_providers" ("name");
