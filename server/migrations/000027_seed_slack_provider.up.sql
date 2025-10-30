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
    'slack',
    'Slack',
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
    SELECT id FROM "service_providers" WHERE name = 'slack'
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
    'slack_channel_new_message',
    'New channel message',
    'Emits an event when a new message appears in the selected Slack channel',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Slack identity',
                'type', 'identity',
                'provider', 'slack',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'channelId',
                'label', 'Channel ID',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Slack channel ID, for example C0123456789'
            ),
            jsonb_build_object(
                'key', 'limit',
                'label', 'Messages per poll',
                'type', 'integer',
                'required', FALSE,
                'minimum', 1,
                'maximum', 200,
                'default', 50
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 10,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://slack.com/api/conversations.history',
                'method', 'GET',
                'itemsPath', 'messages',
                'fingerprintField', 'ts',
                'occurredAtField', 'ts',
                'query', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'channel',
                        'template', '{{params.channelId}}'
                    ),
                    jsonb_build_object(
                        'name', 'limit',
                        'template', '{{params.limit}}',
                        'default', '50',
                        'skipIfEmpty', TRUE
                    ),
                    jsonb_build_object(
                        'name', 'oldest',
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
                    'provider', 'slack'
                ),
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'ts'
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
    SELECT id FROM "service_providers" WHERE name = 'slack'
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
    'slack_post_message',
    'Send Slack message',
    'Sends a message to the selected Slack channel using the linked identity',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Slack identity',
                'type', 'identity',
                'provider', 'slack',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'channelId',
                'label', 'Channel ID',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Slack channel ID, for example C0123456789'
            ),
            jsonb_build_object(
                'key', 'text',
                'label', 'Message text',
                'type', 'textarea',
                'required', TRUE,
                'helperText', 'Supports Slack formatting and emoji codes'
            ),
            jsonb_build_object(
                'key', 'threadTs',
                'label', 'Thread timestamp',
                'type', 'text',
                'required', FALSE,
                'helperText', 'Optional thread timestamp (ts) to reply within a thread'
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
