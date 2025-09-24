ALTER TABLE "area_links" DROP CONSTRAINT IF EXISTS "fk_area_links_component_config";
ALTER TABLE "area_links" DROP CONSTRAINT IF EXISTS "fk_area_links_area";
DROP INDEX IF EXISTS "uq_area_links_single_action";
DROP INDEX IF EXISTS "area_links_index_order";
DROP INDEX IF EXISTS "area_links_index_component_config";
DROP INDEX IF EXISTS "area_links_index_area_role";
DROP TABLE IF EXISTS "area_links";
