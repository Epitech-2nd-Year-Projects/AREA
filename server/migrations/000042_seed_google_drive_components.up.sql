WITH provider AS (
    SELECT id FROM "service_providers" WHERE name = 'google'
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
    'gdrive_new_file_in_folder',
    'New file in folder',
    'Triggers when a new file is added to a specific folder in your Google Drive',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Google identity',
                'type', 'identity',
                'provider', 'google',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'folderId',
                'label', 'Folder ID',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Google Drive folder ID (found in the folder URL)'
            ),
            jsonb_build_object(
                'key', 'pageSize',
                'label', 'Results per poll',
                'type', 'integer',
                'required', FALSE,
                'minimum', 1,
                'maximum', 1000,
                'default', 50
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 30,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://www.googleapis.com/drive/v3/files',
                'method', 'GET',
                'itemsPath', 'files',
                'fingerprintField', 'id',
                'occurredAtField', 'createdTime',
                'query', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'q',
                        'template', '"{{params.folderId}}" in parents and trashed=false',
                        'skipIfEmpty', TRUE
                    ),
                    jsonb_build_object(
                        'name', 'pageSize',
                        'template', '{{params.pageSize}}',
                        'default', '50',
                        'skipIfEmpty', TRUE
                    ),
                    jsonb_build_object(
                        'name', 'orderBy',
                        'value', 'createdTime desc'
                    ),
                    jsonb_build_object(
                        'name', 'spaces',
                        'value', 'drive'
                    ),
                    jsonb_build_object(
                        'name', 'fields',
                        'value', 'files(id,name,mimeType,createdTime,modifiedTime,webViewLink)'
                    ),
                    jsonb_build_object(
                        'name', 'modifiedTimeMin',
                        'template', '{{cursor.last_seen_ts}}',
                        'skipIfEmpty', TRUE
                    )
                ),
                'headers', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'Accept',
                        'value', 'application/json'
                    ),
                    jsonb_build_object(
                        'name', 'Authorization',
                        'template', 'Bearer {{identity.accessToken}}'
                    )
                ),
                'auth', jsonb_build_object(
                    'type', 'oauth',
                    'identityParam', 'identityId',
                    'provider', 'google'
                ),
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'modifiedTime'
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
    SELECT id FROM "service_providers" WHERE name = 'google'
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
    'gdrive_file_with_name_created',
    'File with specific name created',
    'Triggers when a file with a specific name or extension is created in your Google Drive',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Google identity',
                'type', 'identity',
                'provider', 'google',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'searchQuery',
                'label', 'File name or extension',
                'type', 'text',
                'required', TRUE,
                'maxLength', 256,
                'helperText', 'e.g., "*.pdf" or "report" to match file names'
            ),
            jsonb_build_object(
                'key', 'pageSize',
                'label', 'Results per poll',
                'type', 'integer',
                'required', FALSE,
                'minimum', 1,
                'maximum', 1000,
                'default', 50
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 30,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://www.googleapis.com/drive/v3/files',
                'method', 'GET',
                'itemsPath', 'files',
                'fingerprintField', 'id',
                'occurredAtField', 'createdTime',
                'query', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'q',
                        'template', 'name contains "{{params.searchQuery}}" and trashed=false',
                        'skipIfEmpty', TRUE
                    ),
                    jsonb_build_object(
                        'name', 'pageSize',
                        'template', '{{params.pageSize}}',
                        'default', '50',
                        'skipIfEmpty', TRUE
                    ),
                    jsonb_build_object(
                        'name', 'orderBy',
                        'value', 'createdTime desc'
                    ),
                    jsonb_build_object(
                        'name', 'spaces',
                        'value', 'drive'
                    ),
                    jsonb_build_object(
                        'name', 'fields',
                        'value', 'files(id,name,mimeType,createdTime,modifiedTime,webViewLink)'
                    ),
                    jsonb_build_object(
                        'name', 'modifiedTimeMin',
                        'template', '{{cursor.last_seen_ts}}',
                        'skipIfEmpty', TRUE
                    )
                ),
                'headers', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'Accept',
                        'value', 'application/json'
                    ),
                    jsonb_build_object(
                        'name', 'Authorization',
                        'template', 'Bearer {{identity.accessToken}}'
                    )
                ),
                'auth', jsonb_build_object(
                    'type', 'oauth',
                    'identityParam', 'identityId',
                    'provider', 'google'
                ),
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'modifiedTime'
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
    SELECT id FROM "service_providers" WHERE name = 'google'
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
    'gdrive_move_file',
    'Move file to folder',
    'Moves a file to a specific folder in your Google Drive',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Google identity',
                'type', 'identity',
                'provider', 'google',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'fileId',
                'label', 'File ID',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Google Drive file ID to move'
            ),
            jsonb_build_object(
                'key', 'destinationFolderId',
                'label', 'Destination folder ID',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Google Drive folder ID where file will be moved'
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