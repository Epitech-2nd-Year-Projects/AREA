DELETE FROM "service_components"
WHERE "name" IN ('outlook_new_email', 'outlook_send_email')
  AND "version" = 1;

DELETE FROM "service_providers"
WHERE "name" = 'microsoft';
