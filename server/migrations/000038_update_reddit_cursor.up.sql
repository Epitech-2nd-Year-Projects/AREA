WITH target AS (
    SELECT
        sc.id,
        jsonb_agg(elem) FILTER (WHERE elem->>'name' <> 'after') AS filtered_query
    FROM service_components sc
    JOIN service_providers sp ON sp.id = sc.provider_id
    CROSS JOIN LATERAL jsonb_array_elements(COALESCE(sc.metadata #> '{ingestion,http,query}', '[]'::jsonb)) AS elem
    WHERE sc.kind = 'action'
      AND sc.name = 'reddit_new_post'
      AND sp.name = 'reddit'
    GROUP BY sc.id
)
UPDATE service_components sc
SET metadata = jsonb_set(
        jsonb_set(
            sc.metadata,
            '{ingestion,http,query}',
            COALESCE(target.filtered_query, '[]'::jsonb),
            false
        ),
        '{ingestion,http,cursor,key}',
        to_jsonb('reddit_new_post_cursor'::text),
        true
    ),
    updated_at = NOW()
FROM target
WHERE sc.id = target.id;
