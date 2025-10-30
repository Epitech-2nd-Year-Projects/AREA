WITH target AS (
    SELECT
        sc.id,
        jsonb_agg(elem) AS restored_query
    FROM service_components sc
    JOIN service_providers sp ON sp.id = sc.provider_id
    CROSS JOIN LATERAL (
        SELECT elem
        FROM jsonb_array_elements(COALESCE(sc.metadata #> '{ingestion,http,query}', '[]'::jsonb)) AS elem
        WHERE elem->>'name' <> 'after'
        UNION ALL
        SELECT jsonb_build_object(
            'name', 'after',
            'template', '{{cursor.last_seen_name}}',
            'skipIfEmpty', TRUE
        )
    ) AS elem
    WHERE sc.kind = 'action'
      AND sc.name = 'reddit_new_post'
      AND sp.name = 'reddit'
    GROUP BY sc.id
)
UPDATE service_components sc
SET metadata = jsonb_set(
        (sc.metadata #- '{ingestion,http,cursor,key}'),
        '{ingestion,http,query}',
        COALESCE(target.restored_query, '[]'::jsonb),
        false
    ),
    updated_at = NOW()
FROM target
WHERE sc.id = target.id;
