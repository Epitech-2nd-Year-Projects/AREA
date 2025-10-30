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
    'gitlab',
    'GitLab',
    'development',
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
    SELECT id FROM "service_providers" WHERE name = 'gitlab'
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
    'repo_new_stars',
    'New project star',
    'Emits an event when the selected project gains a new star',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'GitLab identity',
                'type', 'identity',
                'provider', 'gitlab',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'owner',
                'label', 'Project namespace',
                'type', 'text',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'repository',
                'label', 'Project name',
                'type', 'text',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'perPage',
                'label', 'Results per page',
                'type', 'integer',
                'required', FALSE,
                'minimum', 1,
                'maximum', 100,
                'default', 30
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 5,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://gitlab.com/api/v4/projects/{{params.owner}}%2F{{params.repository}}/starrers',
                'method', 'GET',
                'auth', jsonb_build_object(
                    'type', 'oauth',
                    'identityParam', 'identityId',
                    'provider', 'gitlab'
                ),
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
                        'name', 'per_page',
                        'template', '{{params.perPage}}',
                        'default', '30',
                        'skipIfEmpty', TRUE
                    )
                ),
                'fingerprintField', 'user.id',
                'occurredAtField', 'starred_since',
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'user.id'
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
    SELECT id FROM "service_providers" WHERE name = 'gitlab'
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
    'gitlab_create_issue',
    'Create GitLab issue',
    'Creates an issue in the selected GitLab project using the linked identity',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'GitLab identity',
                'type', 'identity',
                'provider', 'gitlab',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'owner',
                'label', 'Project namespace',
                'type', 'text',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'repository',
                'label', 'Project name',
                'type', 'text',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'title',
                'label', 'Issue title',
                'type', 'text',
                'required', TRUE,
                'maxLength', 256
            ),
            jsonb_build_object(
                'key', 'body',
                'label', 'Issue description',
                'type', 'textarea',
                'required', FALSE,
                'maxLength', 2000
            ),
            jsonb_build_object(
                'key', 'labels',
                'label', 'Labels',
                'type', 'text',
                'required', FALSE,
                'helperText', 'Optional comma separated list of labels applied to the new issue'
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

