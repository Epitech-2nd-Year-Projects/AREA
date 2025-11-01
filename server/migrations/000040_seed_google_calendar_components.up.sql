-- Seed Google Calendar Actions and Reactions
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
    'action',
    'gcalendar_event_starting_soon',
    'Event starting soon',
    'Triggers when an event in your Google Calendar is about to start',
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
                'key', 'calendarId',
                'label', 'Calendar',
                'type', 'text',
                'required', TRUE,
                'default', 'primary',
                'helperText', 'Calendar ID (default: primary)'
            ),
            jsonb_build_object(
                'key', 'minutesBefore',
                'label', 'Minutes before event',
                'type', 'integer',
                'required', TRUE,
                'minimum', 1,
                'maximum', 1440,
                'default', 15
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 60,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://www.googleapis.com/calendar/v3/calendars/{{params.calendarId}}/events',
                'method', 'GET',
                'itemsPath', 'items',
                'fingerprintField', 'id',
                'occurredAtField', 'start.dateTime',
                'query', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'maxResults',
                        'value', '10'
                    ),
                    jsonb_build_object(
                        'name', 'showDeleted',
                        'value', 'false'
                    ),
                    jsonb_build_object(
                        'name', 'orderBy',
                        'value', 'startTime'
                    ),
                    jsonb_build_object(
                        'name', 'singleEvents',
                        'value', 'true'
                    ),
                    jsonb_build_object(
                        'name', 'timeMin',
                        'template', '{{now_rfc3339}}',
                        'skipIfEmpty', TRUE
                    ),
                    jsonb_build_object(
                        'name', 'updatedMin',
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
                    'provider', 'google'
                ),
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'updated'
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
    'action',
    'gcalendar_event_with_keyword',
    'Event with keyword added',
    'Triggers when an event containing a specific keyword is added to your Google Calendar',
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
                'key', 'calendarId',
                'label', 'Calendar',
                'type', 'text',
                'required', TRUE,
                'default', 'primary',
                'helperText', 'Calendar ID (default: primary)'
            ),
            jsonb_build_object(
                'key', 'keyword',
                'label', 'Keyword to match',
                'type', 'text',
                'required', TRUE,
                'maxLength', 256
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 30,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://www.googleapis.com/calendar/v3/calendars/{{params.calendarId}}/events',
                'method', 'GET',
                'itemsPath', 'items',
                'fingerprintField', 'id',
                'occurredAtField', 'created',
                'query', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'maxResults',
                        'value', '25'
                    ),
                    jsonb_build_object(
                        'name', 'showDeleted',
                        'value', 'false'
                    ),
                    jsonb_build_object(
                        'name', 'orderBy',
                        'value', 'updated'
                    ),
                    jsonb_build_object(
                        'name', 'q',
                        'template', '{{params.keyword}}',
                        'skipIfEmpty', TRUE
                    ),
                    jsonb_build_object(
                        'name', 'updatedMin',
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
                    'provider', 'google'
                ),
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'updated'
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
    'gcalendar_create_event',
    'Create calendar event',
    'Creates a new event in your Google Calendar with specified title, date, and time',
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
                'key', 'calendarId',
                'label', 'Calendar',
                'type', 'text',
                'required', TRUE,
                'default', 'primary',
                'helperText', 'Calendar ID (default: primary)'
            ),
            jsonb_build_object(
                'key', 'summary',
                'label', 'Event title',
                'type', 'text',
                'required', TRUE,
                'maxLength', 512
            ),
            jsonb_build_object(
                'key', 'description',
                'label', 'Event description',
                'type', 'textarea',
                'required', FALSE,
                'maxLength', 8192
            ),
            jsonb_build_object(
                'key', 'startTime',
                'label', 'Start date and time',
                'type', 'datetime',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'endTime',
                'label', 'End date and time',
                'type', 'datetime',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'location',
                'label', 'Location',
                'type', 'text',
                'required', FALSE,
                'maxLength', 512
            ),
            jsonb_build_object(
                'key', 'attendees',
                'label', 'Attendees',
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