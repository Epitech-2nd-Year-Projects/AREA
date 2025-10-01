CREATE TABLE "email_verification_tokens" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "token" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ NOT NULL,
    "consumed_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "uq_email_verification_tokens_token" ON "email_verification_tokens" ("token");
CREATE INDEX "email_verification_tokens_index_user_id" ON "email_verification_tokens" ("user_id");
CREATE INDEX "email_verification_tokens_index_expires_at" ON "email_verification_tokens" ("expires_at");

ALTER TABLE "email_verification_tokens"
    ADD CONSTRAINT "fk_email_verification_tokens_user"
        FOREIGN KEY ("user_id") REFERENCES "users"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
