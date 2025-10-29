WITH provider AS (
    SELECT id FROM "service_providers" WHERE name = 'linear'
),
target AS (
    SELECT id
    FROM "service_components"
    WHERE provider_id IN (SELECT id FROM provider)
      AND kind = 'action'
      AND name = 'linear_issue_created'
)
UPDATE "service_components"
SET "metadata" = jsonb_set(
        jsonb_set(
            metadata,
            '{ingestion,http,bodyTemplate}',
            to_jsonb('{"query":"query Issues($teamId: String!) { issues(filter: { team: { id: { eq: $teamId } } }, first: 50) { nodes { id createdAt identifier title description url } } }","variables":{"teamId":"{{params.teamId}}"}}'::text)
        ),
        '{ingestion,http,cursor}',
        '{"key":"linear_issue_cursor","source":"item","itemPath":"createdAt"}'::jsonb
    ),
    "updated_at" = NOW()
WHERE id IN (SELECT id FROM target);
