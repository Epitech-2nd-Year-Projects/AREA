-- Seed Notion service provider with page-created action and create-page reaction

INSERT INTO "service_providers" (
    "id",
    "name",
    "display_name",
    "category",
    "oauth_type",
    "auth_config",
    "is_enabled"
)
VALUES (
    gen_random_uuid(),
    'notion',
    'Notion',
    'productivity',
    'oauth2',
    '{}'::jsonb,
    TRUE
)
ON CONFLICT ("name") DO UPDATE
    SET "display_name" = EXCLUDED."display_name",
        "category" = EXCLUDED."category",
        "oauth_type" = EXCLUDED."oauth_type",
        "auth_config" = EXCLUDED."auth_config",
        "is_enabled" = TRUE,
        "updated_at" = NOW();

WITH provider AS (
    SELECT id FROM "service_providers" WHERE name = 'notion'
)
INSERT INTO "service_components" (
    "id",
    "provider_id",
    "kind",
    "name",
    "display_name",
    "description",
    "version",
    "metadata",
    "is_enabled"
)
SELECT
    gen_random_uuid(),
    provider.id,
    'action',
    'notion_page_created',
    'Page created in database',
    'Emits an event when a new page is created in the selected Notion database',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Notion identity',
                'type', 'identity',
                'provider', 'notion',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'databaseId',
                'label', 'Database ID',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Paste the Notion database ID (32 characters, with or without dashes)'
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 30,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://api.notion.com/v1/databases/{{params.databaseId}}/query',
                'method', 'POST',
                'itemsPath', 'results',
                'fingerprintField', 'id',
                'occurredAtField', 'created_time',
                'bodyTemplate', '{"page_size":20,"sorts":[{"timestamp":"created_time","direction":"ascending"}]}',
                'headers', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'Accept',
                        'value', 'application/json'
                    ),
                    jsonb_build_object(
                        'name', 'Content-Type',
                        'value', 'application/json'
                    ),
                    jsonb_build_object(
                        'name', 'Authorization',
                        'template', 'Bearer {{identity.accessToken}}'
                    ),
                    jsonb_build_object(
                        'name', 'Notion-Version',
                        'value', '2022-06-28'
                    ),
                    jsonb_build_object(
                        'name', 'User-Agent',
                        'value', 'AREA-Server'
                    )
                ),
                'auth', jsonb_build_object(
                    'type', 'oauth',
                    'identityParam', 'identityId',
                    'provider', 'notion'
                ),
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'created_time',
                    'key', 'notion_pages_cursor'
                )
            )
        )
    ),
    TRUE
FROM provider
ON CONFLICT ("provider_id", "kind", "name", "version")
DO UPDATE SET
    "display_name" = EXCLUDED."display_name",
    "description" = EXCLUDED."description",
    "metadata" = EXCLUDED."metadata",
    "is_enabled" = EXCLUDED."is_enabled",
    "updated_at" = NOW();

WITH provider AS (
    SELECT id FROM "service_providers" WHERE name = 'notion'
)
INSERT INTO "service_components" (
    "id",
    "provider_id",
    "kind",
    "name",
    "display_name",
    "description",
    "version",
    "metadata",
    "is_enabled"
)
SELECT
    gen_random_uuid(),
    provider.id,
    'reaction',
    'notion_create_page',
    'Create page in database',
    'Creates a Notion page in the selected database using the linked identity',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Notion identity',
                'type', 'identity',
                'provider', 'notion',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'databaseId',
                'label', 'Database ID',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Destination database where the new page will be created'
            ),
            jsonb_build_object(
                'key', 'title',
                'label', 'Page title',
                'type', 'text',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'content',
                'label', 'Page content',
                'type', 'textarea',
                'required', FALSE,
                'helperText', 'Optional paragraph content inserted in the page body'
            )
        )
    ),
    TRUE
FROM provider
ON CONFLICT ("provider_id", "kind", "name", "version")
DO UPDATE SET
    "display_name" = EXCLUDED."display_name",
    "description" = EXCLUDED."description",
    "metadata" = EXCLUDED."metadata",
    "is_enabled" = EXCLUDED."is_enabled",
    "updated_at" = NOW();

