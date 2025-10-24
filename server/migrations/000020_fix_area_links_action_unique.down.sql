DROP INDEX IF EXISTS "uq_area_links_single_action";
CREATE UNIQUE INDEX "uq_area_links_single_action"
    ON "area_links" ("area_id")
    WHERE "role" = 'action';
