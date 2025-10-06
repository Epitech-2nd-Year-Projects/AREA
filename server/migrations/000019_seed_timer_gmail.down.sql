DELETE FROM "service_components"
WHERE "name" IN ('timer_interval', 'gmail_send_email')
  AND "version" = 1;

DELETE FROM "service_providers"
WHERE "name" = 'scheduler';
