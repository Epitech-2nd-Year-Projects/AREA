DELETE FROM "service_components"
WHERE "name" IN ('gcalendar_event_starting_soon', 'gcalendar_event_with_keyword', 'gcalendar_create_event')
AND provider_id IN (SELECT id FROM "service_providers" WHERE name = 'google');