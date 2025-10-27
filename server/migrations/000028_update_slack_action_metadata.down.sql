WITH target AS (
    SELECT sc.id
    FROM "service_components" sc
    JOIN "service_providers" sp ON sp.id = sc.provider_id
    WHERE sp.name = 'slack'
      AND sc.kind = 'action'
      AND sc.name = 'slack_channel_new_message'
      AND sc.version = 1
)
UPDATE "service_components"
SET "metadata" = jsonb_build_object(
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
            'method', 'POST',
            'itemsPath', 'messages',
            'fingerprintField', 'ts',
            'occurredAtField', 'ts',
            'bodyTemplate', '{"channel":"{{params.channelId}}"}',
            'query', jsonb_build_array(
                jsonb_build_object(
                    'name', 'limit',
                    'template', '{{params.limit}}',
                    'default', '50',
                    'skipIfEmpty', TRUE
                )
            ),
            'headers', jsonb_build_array(
                jsonb_build_object(
                    'name', 'Content-Type',
                    'value', 'application/json; charset=utf-8'
                ),
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
)
WHERE id IN (SELECT id FROM target);
