UPDATE "service_components"
SET "is_enabled" = FALSE,
    "updated_at" = NOW()
WHERE "provider_id" = (
    SELECT id FROM "service_providers" WHERE "name" = 'dropbox'
);

UPDATE "service_providers"
SET "is_enabled" = FALSE,
    "updated_at" = NOW()
WHERE "name" = 'dropbox';

