WITH provider AS (
    SELECT id FROM "service_providers" WHERE name = 'zoom'
)
UPDATE "service_components"
SET "metadata" = jsonb_set(
    "metadata",
    '{ingestion,http,auth,scopes}',
    '[]'::jsonb,
    FALSE
)
WHERE "provider_id" = (SELECT id FROM provider)
  AND "name" = 'zoom_meeting_created';
