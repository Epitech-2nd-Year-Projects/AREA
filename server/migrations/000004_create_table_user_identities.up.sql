CREATE TABLE "user_identities" (
                                   "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                                   "user_id" UUID NOT NULL,
                                   "provider" VARCHAR(64) NOT NULL,
                                   "subject" TEXT NOT NULL,
                                   "access_token" TEXT,
                                   "refresh_token" TEXT,
                                   "scopes" TEXT[],
                                   "expires_at" TIMESTAMPTZ,
                                   "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   PRIMARY KEY ("id")
);
CREATE INDEX "user_identities_index_user_id" ON "user_identities" ("user_id");
CREATE INDEX "user_identities_index_provider" ON "user_identities" ("provider");
CREATE UNIQUE INDEX "uq_user_identities_provider_subject"
    ON "user_identities" ("provider","subject");

ALTER TABLE "user_identities"
    ADD CONSTRAINT "fk_user_identities_user"
        FOREIGN KEY ("user_id") REFERENCES "users"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
