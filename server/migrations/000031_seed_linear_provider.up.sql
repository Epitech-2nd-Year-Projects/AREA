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
    'linear',
    'Linear',
    'project_management',
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
    SELECT id FROM "service_providers" WHERE name = 'linear'
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
    'linear_issue_created',
    'New Linear issue',
    'Emits an event when a new issue is created in the selected Linear team',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Linear identity',
                'type', 'identity',
                'provider', 'linear',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'teamId',
                'label', 'Team ID',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Linear team ID, for example team_0123456789abcdef'
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 10,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://api.linear.app/graphql',
                'method', 'POST',
                'itemsPath', 'data.issues.nodes',
                'fingerprintField', 'id',
                'occurredAtField', 'createdAt',
                'bodyTemplate', '{"query":"query Issues($teamId: ID!) { issues(filter: { team: { id: { eq: $teamId } } }, first: 50) { nodes { id createdAt identifier title description url } } }","variables":{"teamId":"{{params.teamId}}"}}',
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
                    )
                ),
                'auth', jsonb_build_object(
                    'type', 'oauth',
                    'identityParam', 'identityId',
                    'provider', 'linear'
                ),
                'cursor', jsonb_build_object(
                    'key', 'linear_issue_cursor',
                    'source', 'fingerprint'
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
    SELECT id FROM "service_providers" WHERE name = 'linear'
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
    'linear_create_issue',
    'Create Linear issue',
    'Creates an issue in the selected Linear team using the linked identity',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Linear identity',
                'type', 'identity',
                'provider', 'linear',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'teamId',
                'label', 'Team ID',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Linear team ID, for example team_0123456789abcdef'
            ),
            jsonb_build_object(
                'key', 'title',
                'label', 'Issue title',
                'type', 'text',
                'required', TRUE,
                'maxLength', 256
            ),
            jsonb_build_object(
                'key', 'description',
                'label', 'Issue description',
                'type', 'textarea',
                'required', FALSE,
                'maxLength', 2000
            ),
            jsonb_build_object(
                'key', 'priority',
                'label', 'Priority',
                'type', 'integer',
                'required', FALSE,
                'minimum', 0,
                'maximum', 4,
                'helperText', 'Priority level from 0 (no priority) to 4 (urgent)'
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
