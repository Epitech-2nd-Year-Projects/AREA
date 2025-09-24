CREATE TABLE "sessions" (
                            "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                            "user_id" UUID NOT NULL,
                            "issued_at" TIMESTAMPTZ NOT NULL,
                            "expires_at" TIMESTAMPTZ NOT NULL,
                            "revoked_at" TIMESTAMPTZ,
                            "ip" VARCHAR(45),
                            "user_agent" TEXT,
                            PRIMARY KEY ("id")
);
CREATE INDEX "sessions_index_user_id" ON "sessions" ("user_id");
CREATE INDEX "sessions_index_expires_at" ON "sessions" ("expires_at");
CREATE INDEX "sessions_index_revoked_at" ON "sessions" ("revoked_at");

ALTER TABLE "sessions"
    ADD CONSTRAINT "fk_sessions_user"
        FOREIGN KEY ("user_id") REFERENCES "users"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
