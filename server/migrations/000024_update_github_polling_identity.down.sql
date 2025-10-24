WITH provider AS (
    SELECT id FROM "service_providers" WHERE name = 'github'
)
UPDATE "service_components"
SET "metadata" = jsonb_build_object(
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
        'intervalSeconds', 5,
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
)
WHERE "provider_id" = (SELECT id FROM provider)
  AND "kind" = 'action'
  AND "name" = 'repo_new_stars';
