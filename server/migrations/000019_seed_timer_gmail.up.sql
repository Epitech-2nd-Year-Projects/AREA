INSERT INTO "service_providers" ("id", "name", "display_name", "category", "oauth_type", "auth_config", "is_enabled")
VALUES (gen_random_uuid(), 'google', 'Google', 'productivity', 'oauth2', '{}'::jsonb, TRUE)
ON CONFLICT ("name") DO UPDATE
    SET "display_name" = EXCLUDED."display_name",
        "category" = EXCLUDED."category",
        "oauth_type" = EXCLUDED."oauth_type",
        "is_enabled" = TRUE,
        "updated_at" = NOW();

INSERT INTO "service_providers" ("id", "name", "display_name", "category", "oauth_type", "auth_config", "is_enabled")
VALUES (gen_random_uuid(), 'scheduler', 'Scheduler', 'utility', 'none', '{}'::jsonb, TRUE)
ON CONFLICT ("name") DO UPDATE
    SET "display_name" = EXCLUDED."display_name",
        "category" = EXCLUDED."category",
        "oauth_type" = EXCLUDED."oauth_type",
        "is_enabled" = TRUE,
        "updated_at" = NOW();

WITH provider AS (
    SELECT id FROM "service_providers" WHERE name = 'scheduler'
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
    'timer_interval',
    'Recurring timer',
    'Triggers on a recurring schedule at the chosen interval',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'frequencyValue',
                'label', 'Frequency value',
                'type', 'integer',
                'required', TRUE,
                'minimum', 1,
                'maximum', 1440
            ),
            jsonb_build_object(
                'key', 'frequencyUnit',
                'label', 'Frequency unit',
                'type', 'enum',
                'required', TRUE,
                'options', jsonb_build_array(
                    jsonb_build_object('value', 'minutes', 'label', 'Minutes'),
                    jsonb_build_object('value', 'hours', 'label', 'Hours'),
                    jsonb_build_object('value', 'days', 'label', 'Days')
                )
            ),
            jsonb_build_object(
                'key', 'startAt',
                'label', 'Start at',
                'type', 'datetime',
                'required', FALSE
            ),
            jsonb_build_object(
                'key', 'timeZone',
                'label', 'Time zone',
                'type', 'timezone',
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
    'gmail_send_email',
    'Send email with Gmail',
    'Delivers an email through the user''s Gmail account',
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
