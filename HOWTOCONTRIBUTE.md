# How to Contribute to AREA

This guide distills the practical steps required to extend the automation platform with new services, actions, reactions, or other core capabilities. It complements the app-specific documentation shipped in `server/docs`, `web/docs`, and `mobile/docs`. When you need deeper architectural background refer to:

- `server/docs/architecture/README.md` – backend hexagonal architecture and data flow.
- `web/docs/DEVELOPER_GUIDE.md` – Next.js front-end conventions, API layer, and UI patterns.
- `mobile/docs/DEVELOPER_GUIDE.md` – Flutter clean-architecture layers and design system.

## Before You Start

- Set up the toolchains described in `README.md` (Go ≥ 1.25, Node.js ≥ 20, Flutter stable).
- Install dependencies in each app (`npm install`, `go mod download`, `flutter pub get`).
- Create a feature branch named `feature/<issue-id>-<feature-name>` and ensure the worktree is clean (`git status`).
- Keep Redoc and OpenAPI docs in sync by editing `server/api/openapi.yaml` alongside code changes.

## Adding or Extending a Service Provider

1. **Model the catalog entry (database)**
   - Copy an existing seed migration in `server/migrations` (e.g. `000034_seed_spotify_provider.up.sql`) and create a new sequential pair (`.up.sql` / `.down.sql`). Populate:
     - `service_providers`: canonical `name`, friendly `display_name`, `category`, `oauth_type`, and `auth_config` (JSONB describing OAuth scopes, prompts, PKCE usage, etc.).
     - `service_components`: one row per action or reaction. Use a stable `name` (machine id), `display_name`, `description`, semantic `version`, and structured `metadata`.
   - Encode component configuration in `metadata.parameters` — an array of objects consumed by all clients. Supported keys include:
     - `key`, `label`, `description`, `type` (`text`, `password`, `integer`, `boolean`, `select`, `identity`, …).
     - `required`, `default`, validation hints (`minimum`, `maximum`).
     - `options` (for selects) and any handler-specific extras (e.g. ingestion cursors).
   - Define ingestion under `metadata.ingestion` for actions. `HTTPPollingHandler` expects fields such as:

     ```json
     {
       "mode": "polling",
       "intervalSeconds": 300,
       "handler": "http",
       "http": {
         "endpoint": "https://api.example.com/events",
         "method": "GET",
         "headers": [
           {
             "name": "Authorization",
             "template": "Bearer {{identity.accessToken}}"
           }
         ],
         "query": [
           {
             "name": "cursor",
             "template": "{{cursor.last_seen_ts}}",
             "skipIfEmpty": true
           }
         ],
         "itemsPath": "data.items",
         "fingerprintField": "id",
         "occurredAtField": "timestamp"
       }
     }
     ```

     See `server/internal/app/area/http_polling_handler.go` for the complete contract.

2. **Wire backend behavior**
   - If the action needs special provisioning (polling schedules, timers, webhook setup) ensure the appropriate provisioner can interpret your metadata:
     - Polling: `area.NewPollingProvisioner` handles `metadata.ingestion.mode = polling`.
     - Timers: `metadata.timer` is processed by `area.TimerScheduler`.
     - Webhooks: extend or implement a new `ComponentWebhookProvisioner` if necessary.
   - Implement reaction execution when adding a new reaction:
     - Create a handler under `server/internal/adapters/outbound/reaction/<provider>/` that satisfies `area.ComponentReactionHandler` (see `server/internal/adapters/outbound/reaction/github/executor.go` for a pattern).
     - Resolve OAuth identities via `identityport.Repository`, perform API calls, and return `outbound.ReactionResult` with request/response diagnostics.
     - Register the handler in `server/cmd/server/main.go` so it is injected into `area.NewCompositeReactionExecutor`.
   - When introducing a new ingestion strategy, add a handler implementing `area.ComponentPollingHandler` and register it next to `NewHTTPPollingHandler`.
   - Update or add repository helpers in `server/internal/adapters/outbound/postgres` if new persistence needs arise.

3. **Expose it through the API**
   - Extend `server/api/openapi.yaml` with any new endpoints, schemas, or enum values.
   - Regenerate the HTTP server stubs:

     ```bash
     (cd server && go generate ./internal/adapters/inbound/http/openapi)
     ```

   - Update Redoc output if the docs are published: `npm run docs:build`.

## Syncing the Web App

- Update DTO contracts in `web/src/lib/api/contracts/openapi` and propagate changes to adapters/hooks under `web/src/lib/api/openapi/<feature>`.
- Ensure new catalog data renders in UI:
  - Extend catalogue views in `web/src/components/services` and area builders in `web/src/components/areas`.
  - The dynamic form (`web/src/components/areas/component-config-sheet.tsx`) reads `metadata.parameters`; add render logic for new parameter `type` values if required.
- Add or update translations in `web/messages/*.json`.
- Refresh or add Vitest coverage in `web/e2e` or `web/src/**/__tests__`.
- Run lint/type/test pipelines: `npm run lint`, `npm run typecheck`, `npm run test`.

## Syncing the Mobile App

- Mirror DTO changes in the data layer:
  - Update models in `mobile/lib/features/services/data/models` (e.g. `service_component_model.dart`) and mapping logic in corresponding repositories.
  - If new metadata fields are required, extend `mobile/lib/features/services/domain/entities` and adjust `ComponentParameter` parsing.
- Update UI flows:
  - The dynamic configuration widget lives in `mobile/lib/features/areas/presentation/widgets/component_configuration_form.dart`; ensure it can render new parameter types or defaults.
  - Adjust pickers in `mobile/lib/features/areas/presentation/widgets/service_and_component_picker.dart` if service discovery changes.
- Add localized strings to `mobile/lib/l10n/*.arb`.
- Validate with `flutter analyze` and `flutter test`.

## Other Core Enhancements

- **Sessions/Auth**: Follow patterns in `server/internal/app/auth` and regenerate OpenAPI if request/response shapes change; update clients in both front-ends.
- **Jobs/Automation**: Extend application services under `server/internal/app/area` or `server/internal/app/automation`. Keep domain mutations inside `server/internal/domain`.
- **Background workers**: New queue behavior belongs in `server/internal/ports/outbound/queue` and adapter implementations under `server/internal/adapters/outbound/queue`.

## Testing and Validation Checklist

- `go test ./...` and `go vet ./...` inside `server`.
- `npm run lint` / `npm run test` / `npm run typecheck` inside `web`.
- `flutter analyze` and `flutter test` inside `mobile`.
- Exercise critical flows locally via Docker Compose (`docker compose up`) to ensure services, actions, and reactions interact end-to-end.
- If migrations touch seed data, validate idempotency by running them twice against a dev database.

## Submitting a Pull Request

- Commits must follow the Conventional Commits spec (`feat:`, `fix:`, `chore:`, etc.); Husky will enforce this locally (`npm install && npx husky init`).
- Update `README.md` or in-app docs when behavior changes.
- Attach screenshots or GIFs for UI-affecting changes in web/mobile.
- Describe new or changed environment variables and OAuth scopes in the PR body.
- Ensure `git status` shows only intentional changes before opening the PR.

Following these steps keeps the server, web, and mobile applications aligned while expanding AREA’s automation catalog safely. When in doubt, inspect existing providers such as the GitHub seeds in `server/migrations/000022_seed_github_provider.up.sql` and mirror their patterns.
