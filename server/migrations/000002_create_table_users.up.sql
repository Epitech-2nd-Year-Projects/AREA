CREATE TABLE "users" (
                         "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                         "email" VARCHAR(320) NOT NULL,
                         "password_hash" TEXT,
                         "status" "user_status" NOT NULL DEFAULT 'pending',
                         "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                         "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                         "last_login_at" TIMESTAMPTZ,
                         PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "uq_users_email_lower" ON "users" (lower("email"));
CREATE INDEX "users_index_status" ON "users" ("status");
