CREATE TABLE "areas" (
                         "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                         "user_id" UUID NOT NULL,
                         "name" VARCHAR(128) NOT NULL,
                         "description" TEXT,
                         "status" "area_status" NOT NULL DEFAULT 'enabled',
                         "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                         "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                         PRIMARY KEY ("id")
);
CREATE INDEX "areas_index_user_id" ON "areas" ("user_id");
CREATE INDEX "areas_index_status" ON "areas" ("status");

ALTER TABLE "areas"
    ADD CONSTRAINT "fk_areas_user"
        FOREIGN KEY ("user_id") REFERENCES "users"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
