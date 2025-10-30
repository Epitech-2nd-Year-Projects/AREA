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
    'spotify',
    'Spotify',
    'music',
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
    SELECT id FROM "service_providers" WHERE name = 'spotify'
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
    'spotify_track_liked',
    'Track liked',
    'Emits an event when a new track is saved to the user''s Spotify library',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Spotify identity',
                'type', 'identity',
                'provider', 'spotify',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'limit',
                'label', 'Tracks per poll',
                'type', 'integer',
                'required', FALSE,
                'default', 20,
                'minimum', 1,
                'maximum', 50
            )
        ),
        'ingestion', jsonb_build_object(
            'mode', 'polling',
            'intervalSeconds', 20,
            'handler', 'http',
            'http', jsonb_build_object(
                'endpoint', 'https://api.spotify.com/v1/me/tracks',
                'method', 'GET',
                'itemsPath', 'items',
                'fingerprintField', 'track.id',
                'occurredAtField', 'added_at',
                'query', jsonb_build_array(
                    jsonb_build_object(
                        'name', 'limit',
                        'template', '{{params.limit}}',
                        'default', '20',
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
                    'provider', 'spotify',
                    'scopes', jsonb_build_array(
                        'user-library-read'
                    )
                ),
                'cursor', jsonb_build_object(
                    'source', 'item',
                    'itemPath', 'added_at',
                    'key', 'spotify_saved_tracks_cursor'
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
    SELECT id FROM "service_providers" WHERE name = 'spotify'
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
    'spotify_add_track_to_playlist',
    'Add track to playlist',
    'Adds the selected track to a Spotify playlist using the linked identity',
    1,
    jsonb_build_object(
        'parameters', jsonb_build_array(
            jsonb_build_object(
                'key', 'identityId',
                'label', 'Spotify identity',
                'type', 'identity',
                'provider', 'spotify',
                'required', TRUE
            ),
            jsonb_build_object(
                'key', 'playlistId',
                'label', 'Playlist ID or URL',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Accepts a playlist ID, spotify:playlist URI, or share URL'
            ),
            jsonb_build_object(
                'key', 'trackUri',
                'label', 'Track URI or link',
                'type', 'text',
                'required', TRUE,
                'helperText', 'Accepts a spotify:track URI, track ID, or share URL'
            ),
            jsonb_build_object(
                'key', 'position',
                'label', 'Insert position',
                'type', 'integer',
                'required', FALSE,
                'minimum', 0,
                'helperText', 'Optional 0-based index for the insert position'
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
