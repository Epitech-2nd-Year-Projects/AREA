-- Seed GitHub service provider for catalog exposure

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
    'github',
    'GitHub',
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
    SELECT id FROM "service_providers" WHERE name = 'github'
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
    'New repository star',
    'Emits an event when the selected repository gains a new star',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'owner',
                'label', 'Repository owner',
                'type', 'text',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'repository',
                'label', 'Repository name',
                'type', 'text',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'token',
                'label', 'Personal access token',
                'type', 'password',
                'required', FALSE,
                'helperText', 'Optional token used to access private repositories or increase rate limits'
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
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://api.github.com/repos/{{params.owner}}/{{params.repository}}/stargazers',
                'method', 'GET',
                'headers', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'Accept',
                        'value', 'application/vnd.github.v3.star+json'
                    ),
                    jsonb_build_object(
                        'name', 'Authorization',
                        'template', 'token {{params.token}}',
                        'skipIfEmpty', TRUE
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
                'occurredAtField', 'starred_at',
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
    SELECT id FROM "service_providers" WHERE name = 'github'
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
    'github_create_issue',
    'Create GitHub issue',
    'Creates an issue in the selected GitHub repository using the linked identity',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'GitHub identity',
                'type', 'identity',
                'provider', 'github',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'owner',
                'label', 'Repository owner',
                'type', 'text',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'repository',
                'label', 'Repository name',
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
                'label', 'Issue body',
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
