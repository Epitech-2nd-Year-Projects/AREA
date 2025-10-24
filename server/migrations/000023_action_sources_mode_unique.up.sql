-- Ensure one action source per component configuration and ingestion mode

CREATE UNIQUE INDEX IF NOT EXISTS "uq_action_sources_polling_config"
    ON "action_sources" ("component_config_id")
    WHERE "mode" = 'polling';

CREATE UNIQUE INDEX IF NOT EXISTS "uq_action_sources_webhook_config"
    ON "action_sources" ("component_config_id")
    WHERE "mode" = 'webhook';
