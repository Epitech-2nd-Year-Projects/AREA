-- Seed Microsoft service provider with Outlook email polling action and send mail reaction

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
    'microsoft',
    'Microsoft',
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
    SELECT id FROM "service_providers" WHERE name = 'microsoft'
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
    'outlook_new_email',
    'New Outlook email',
    'Emits an event when a new email arrives in the selected Outlook folder',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Microsoft identity',
                'type', 'identity',
                'provider', 'microsoft',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'folderId',
                'label', 'Mail folder',
                'type', 'text',
                'required', TRUE,
                'default', 'Inbox',
                'helperText', 'Folder display name or identifier (for example Inbox)'
            ),
            jsonb_build_object(
                'key', 'maxResults',
                'label', 'Messages per poll',
                'type', 'integer',
                'required', FALSE,
                'minimum', 1,
                'maximum', 50,
                'default', 25
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 15,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://graph.microsoft.com/v1.0/me/mailFolders/{{params.folderId}}/messages',
                'method', 'GET',
                'itemsPath', 'value',
                'fingerprintField', 'id',
                'occurredAtField', 'receivedDateTime',
                'query', jsonb_build_array(
                    jsonb_build_object(
                        'name', '$orderby',
                        'value', 'receivedDateTime desc'
                    ),
                    jsonb_build_object(
                        'name', '$top',
                        'template', '{{params.maxResults}}',
                        'default', '25',
                        'skipIfEmpty', TRUE
                    ),
                    jsonb_build_object(
                        'name', '$filter',
                        'template', 'receivedDateTime gt {{cursor.last_seen_ts}}',
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
                    'provider', 'microsoft'
                ),
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'receivedDateTime'
                ),
                'skipItems', jsonb_build_array(
                    jsonb_build_object(
                        'path', 'isDraft',
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
    SELECT id FROM "service_providers" WHERE name = 'microsoft'
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
    'outlook_send_email',
    'Send Outlook email',
    'Sends an email through the user''s Outlook account',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Microsoft identity',
                'type', 'identity',
                'provider', 'microsoft',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'to',
                'label', 'Recipients',
                'type', 'emailList',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'subject',
                'label', 'Subject',
                'type', 'text',
                'required', TRUE,
                'maxLength', 256
            ),
            jsonb_build_object(
                'key', 'body',
                'label', 'Body',
                'type', 'textarea',
                'required', TRUE,
                'maxLength', 8192
            ),
            jsonb_build_object(
                'key', 'cc',
                'label', 'Cc',
                'type', 'emailList',
                'required', FALSE
            ),
            jsonb_build_object(
                'key', 'bcc',
                'label', 'Bcc',
                'type', 'emailList',
                'required', FALSE
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
