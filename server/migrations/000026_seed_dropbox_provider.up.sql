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
    'dropbox',
    'Dropbox',
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
    SELECT id FROM "service_providers" WHERE name = 'dropbox'
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
    'dropbox_file_added',
    'File added to folder',
    'Emits an event when a new file is detected in the selected Dropbox folder',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Dropbox identity',
                'type', 'identity',
                'provider', 'dropbox',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'path',
                'label', 'Folder path',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Path within Dropbox, for example /Reports'
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 10,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://api.dropboxapi.com/2/files/list_folder',
                'method', 'POST',
                'itemsPath', 'entries',
                'fingerprintField', 'id',
                'occurredAtField', 'server_modified',
            'bodyTemplate', '{"path":"{{params.path}}","recursive":false,"include_deleted":false,"include_media_info":false,"include_mounted_folders":true,"include_non_downloadable_files":true}',
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
                        'name', 'User-Agent',
                        'value', 'AREA-Server'
                    )
                ),
                'auth', jsonb_build_object(
                    'type', 'oauth',
                    'identityParam', 'identityId',
                    'provider', 'dropbox'
                ),
                'cursor', jsonb_build_object(
                    'key', 'dropbox_file_cursor',
                    'source', 'response',
                    'responsePath', 'cursor'
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
    SELECT id FROM "service_providers" WHERE name = 'dropbox'
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
    'dropbox_create_folder',
    'Create Dropbox folder',
    'Creates a folder in Dropbox using the linked identity',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Dropbox identity',
                'type', 'identity',
                'provider', 'dropbox',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'path',
                'label', 'Folder path',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Path to create, for example /Projects/Reports'
            ),
            jsonb_build_object(
                'key', 'autorename',
                'label', 'Auto rename if exists',
                'type', 'checkbox',
                'required', FALSE,
                'default', FALSE
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
