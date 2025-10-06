CREATE UNIQUE INDEX IF NOT EXISTS "uq_action_sources_schedule_config"
    ON "action_sources" ("component_config_id")
    WHERE "mode" = 'schedule';
