CREATE TABLE "service_component_examples" (
                                              "id" UUID NOT NULL DEFAULT gen_random_uuid(),
                                              "component_id" UUID NOT NULL,
                                              "example_input" JSONB,
                                              "example_output" JSONB,
                                              PRIMARY KEY ("id")
);

ALTER TABLE "service_component_examples"
    ADD CONSTRAINT "fk_component_examples_component"
        FOREIGN KEY ("component_id") REFERENCES "service_components"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
