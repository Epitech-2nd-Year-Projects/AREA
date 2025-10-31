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
    'reddit',
    'Reddit',
    'social',
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
    SELECT id FROM "service_providers" WHERE name = 'reddit'
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
    'reddit_new_post',
    'New subreddit post',
    'Emits an event when a new post is published in the selected subreddit',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Reddit identity',
                'type', 'identity',
                'provider', 'reddit',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'subreddit',
                'label', 'Subreddit',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Name of the subreddit without the /r/ prefix'
            ),
            jsonb_build_object(
                'key', 'limit',
                'label', 'Posts per poll',
                'type', 'integer',
                'required', FALSE,
                'minimum', 1,
                'maximum', 100,
                'default', 25
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 30,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://oauth.reddit.com/r/{{params.subreddit}}/new',
                'method', 'GET',
                'itemsPath', 'data.children',
                'fingerprintField', 'data.id',
                'occurredAtField', 'data.created_utc',
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'data.name'
                ),
                'query', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'limit',
                        'template', '{{params.limit}}',
                        'default', '25',
                        'skipIfEmpty', TRUE
                    ),
                    jsonb_build_object(
                        'name', 'after',
                        'template', '{{cursor.last_seen_name}}',
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
                    ),
                    jsonb_build_object(
                        'name', 'User-Agent',
                        'value', 'AREA-Server'
                    )
                ),
                'auth', jsonb_build_object(
                    'type', 'oauth',
                    'identityParam', 'identityId',
                    'provider', 'reddit',
                    'scopes', jsonb_build_array('read')
                ),
                'skipItems', jsonb_build_array(
                    jsonb_build_object(
                        'path', 'data.stickied',
                        'equals', 'true'
                    )
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
    SELECT id FROM "service_providers" WHERE name = 'reddit'
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
    'reddit_comment_post',
    'Comment on Reddit post',
    'Posts a comment on the specified Reddit submission using the linked identity',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Reddit identity',
                'type', 'identity',
                'provider', 'reddit',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'thingId',
                'label', 'Post thing ID',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Fullname of the post, for example t3_abc123'
            ),
            jsonb_build_object(
                'key', 'text',
                'label', 'Comment text',
                'type', 'textarea',
                'required', TRUE,
                'maxLength', 10000
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
