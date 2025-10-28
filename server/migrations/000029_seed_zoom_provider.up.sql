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
    'zoom',
    'Zoom',
    'communication',
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
    SELECT id FROM "service_providers" WHERE name = 'zoom'
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
    'zoom_meeting_created',
    'Meeting created',
    'Emits an event when a new Zoom meeting is created for the selected user',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Zoom identity',
                'type', 'identity',
                'provider', 'zoom',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'userId',
                'label', 'User ID or email',
                'type', 'text',
                'required', TRUE,
                'default', 'me',
                'helperText', 'Use "me" to monitor your own meetings or provide a Zoom user ID/email'
            ),
            jsonb_build_object(
                'key', 'pageSize',
                'label', 'Results per page',
                'type', 'integer',
                'required', FALSE,
                'minimum', 1,
                'maximum', 300,
                'default', 30
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 30,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://api.zoom.us/v2/users/{{params.userId}}/meetings',
                'method', 'GET',
                'itemsPath', 'meetings',
                'fingerprintField', 'id',
                'occurredAtField', 'created_at',
                'headers', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'Accept',
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
                'query', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'type',
                        'template', 'scheduled'
                    ),
                    jsonb_build_object(
                        'name', 'page_size',
                        'template', '{{params.pageSize}}',
                        'default', '30',
                        'skipIfEmpty', TRUE
                    )
                ),
                'auth', jsonb_build_object(
                    'type', 'oauth',
                    'identityParam', 'identityId',
                    'provider', 'zoom',
                    'scopes', '[]'::jsonb
                ),
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'id'
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
    SELECT id FROM "service_providers" WHERE name = 'zoom'
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
    'zoom_create_meeting',
    'Create Zoom meeting',
    'Creates a Zoom meeting for the selected user using the linked identity',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Zoom identity',
                'type', 'identity',
                'provider', 'zoom',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'userId',
                'label', 'User ID or email',
                'type', 'text',
                'required', FALSE,
                'default', 'me',
                'helperText', 'Use "me" to schedule on your own account or provide a Zoom user ID/email'
            ),
            jsonb_build_object(
                'key', 'topic',
                'label', 'Meeting topic',
                'type', 'text',
                'required', TRUE,
                'maxLength', 200
            ),
            jsonb_build_object(
                'key', 'startTime',
                'label', 'Start time',
                'type', 'datetime',
                'required', FALSE,
                'helperText', 'Leave empty to create an instant meeting'
            ),
            jsonb_build_object(
                'key', 'timeZone',
                'label', 'Time zone',
                'type', 'timezone',
                'required', FALSE
            ),
            jsonb_build_object(
                'key', 'duration',
                'label', 'Duration (minutes)',
                'type', 'integer',
                'required', FALSE,
                'minimum', 1,
                'maximum', 1440
            ),
            jsonb_build_object(
                'key', 'agenda',
                'label', 'Agenda',
                'type', 'textarea',
                'required', FALSE,
                'maxLength', 2000
            ),
            jsonb_build_object(
                'key', 'password',
                'label', 'Passcode',
                'type', 'text',
                'required', FALSE,
                'maxLength', 10
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
