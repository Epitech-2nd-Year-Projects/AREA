CREATE TABLE "user_service_subscriptions" (
                                              "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                                              "user_id" UUID NOT NULL,
                                              "provider_id" UUID NOT NULL,
                                              "identity_id" UUID,
                                              "status" "subscription_status" NOT NULL DEFAULT 'active',
                                              "scope_grants" TEXT[],
                                              "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                              "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                              PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "uq_subscription" ON "user_service_subscriptions" ("user_id","provider_id");
CREATE INDEX "subscriptions_index_identity_id" ON "user_service_subscriptions" ("identity_id");
CREATE INDEX "subscriptions_index_status" ON "user_service_subscriptions" ("status");

ALTER TABLE "user_service_subscriptions"
    ADD CONSTRAINT "fk_subscriptions_user"
        FOREIGN KEY ("user_id") REFERENCES "users"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "user_service_subscriptions"
    ADD CONSTRAINT "fk_subscriptions_provider"
        FOREIGN KEY ("provider_id") REFERENCES "service_providers"("id")
            ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_service_subscriptions"
    ADD CONSTRAINT "fk_subscriptions_identity"
        FOREIGN KEY ("identity_id") REFERENCES "user_identities"("id")
            ON DELETE SET NULL ON UPDATE NO ACTION;
