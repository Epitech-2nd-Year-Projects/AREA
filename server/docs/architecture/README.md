# AREA Server Architecture

## 1. Architectural Overview

The AREA backend follows a hexagonal (ports & adapters) architecture to isolate the core business rules from delivery mechanisms and infrastructure concerns. The design lets us evolve transports (REST, webhooks, workers) and persistence options independently of the domain logic while keeping a clear dependency rule: **outer layers depend on inner layers, never the reverse**.

```
┌──────────────────────────────┐
│        Inbound Adapters      │  Gin HTTP API, schedulers, workers
├───────────────▲──────────────┤
│     Inbound Ports (API)      │  REST controllers, background job contracts
├───────────────▲──────────────┤
│   Application Services       │  Orchestrate use cases, enforce policies
├───────────────▲──────────────┤
│        Domain Core           │  Aggregates, value objects, domain services
├───────────────▼──────────────┤
│    Outbound Ports (SPI)      │  Persistence, identity, notifier, queue
├───────────────▼──────────────┤
│       Outbound Adapters      │  GORM/Postgres, OAuth, Webhooks, Worker queue
└──────────────────────────────┘
```

Cross-cutting platform support (configuration, logging, telemetry) lives alongside adapters but is consumed throughout the stack.

## 2. Directory Map & Responsibilities

### Top-Level

- `cmd/server/` — Composition root; builds the dependency graph, loads configuration, and starts the Gin HTTP server.
- `internal/` — Non-exported implementation code organized by architectural concern (details below).
- `migrations/` — Ordered SQL migrations defining the Postgres schema that underpins AREA entities.
- `docs/` — Living documentation (this file, contribution guides, sequence diagrams, ADRs).
- `test/` — Black-box suites hitting application entry points (REST, jobs) with realistic dependencies.

### `internal/domain`

Pure business modules that encode AREA fundamentals:
- `area/` — AREA aggregate coordinating triggers, reactions, and execution policies.
- `component/` — Service component catalog (actions, reactions, metadata, rate limits).
- `job/` — Delivery job lifecycle, retries, status transitions.
- `service/` — Service registry model and subscription requirements.
- `session/`, `subscription/`, `user/` — Identity, authentication, and user-service binding.

Domain packages are **framework-free**; they only depend on the standard library and each other via well-structured APIs.

### `internal/app`

Application services expose use cases while keeping transaction orchestration and policy enforcement outside the domain:
- `area/` — Create/update AREA automations, validate link chains, schedule triggers.
- `auth/` — Registration, login, OAuth handshakes, and session issuance.
- `automation/` — Trigger evaluation pipeline (from action events to queued jobs).
- `monitoring/` — Health endpoints, delivery log exploration, SLA reporting.

These services depend on inbound ports for request models and outbound ports for infrastructure access.

### `internal/ports`

Contracts that define boundaries between inner layers and outer infrastructure:
- `inbound/http` — Interfaces for handlers to call application services; shapes request/response DTOs.
- `inbound/scheduler` — Contracts for cron/scheduled trigger processors.
- `inbound/worker` — Job processing interfaces invoked by background workers.
- `outbound/repository` — Persistence SPI (users, sessions, areas, jobs, service catalogs, delivery logs).
- `outbound/identity` — OAuth/social login integrations.
- `outbound/notifier` — Webhook/email/push delivery of reactions.
- `outbound/secrets` — Secure storage for encrypted tokens.
- `outbound/queue` — Enqueue and drain trigger jobs for asynchronous execution.

### `internal/adapters`

Technology-specific implementations of ports:
- `inbound/http/gin/` — Gin engine bootstrap, route registration, middleware, and presenter bindings.
- `inbound/http/handlers/` — Request handler implementations mapping HTTP to application commands.
- `inbound/http/middleware/` — AuthN/Z, logging, panic recovery, trace propagation.
- `inbound/http/presenter/` — Serializers transforming application responses into JSON payloads.
- `inbound/scheduler/` — Cron/Temporal/Airflow bindings that call automation ports.
- `inbound/worker/` — Background worker runtime (e.g., BullMQ, Asynq) invoking job processors.
- `outbound/postgres/gorm/` — GORM-backed repository implementations; models, query builders, transactions.
- `outbound/oauth/` — OAuth2 providers for Google/X/Facebook linking and token refresh.
- `outbound/webhook/` — Outbound HTTP clients delivering reaction payloads with retry policies.
- `outbound/mailer/` — Email provider integrations for notifications.
- `outbound/redis/` — Caching/session storage, optional rate limiting.
- `outbound/queue/worker/` — Queue client (e.g., Redis streams) bridging to worker infrastructure.

### `internal/platform`

Cross-cutting infrastructure leveraged across adapters and application modules:
- `config/viper/` — Viper setup and typed configuration hydration (env files, secrets managers).
- `database/gorm/` — GORM initialization, migrations wiring, connection health checks.
- `httpserver/gin/` — HTTP server lifecycle (graceful shutdown, TLS, middleware stack).
- `logging/slog/` — Structured logging configuration, centralized logger factories.
- `telemetry/opentelemetry/` — Metrics/tracing exporters, context propagation helpers.

### `internal/shared`

- `dto/` — Request/response representations decoupled from adapters.
- `validation/` — Validation rules reused across inbound layers.
- `errors/` — Error taxonomy (domain errors, infrastructure errors) with mapping hints for presenters.

## 3. Technology Choices & Impact

| Concern            | Choice  | Rationale & Architectural Placement |
|--------------------|---------|--------------------------------------|
| HTTP API           | Gin     | Fast, expressive router. Lives entirely in inbound HTTP adapter (`internal/adapters/inbound/http/gin`) and `internal/platform/httpserver/gin` for lifecycle. Handlers depend only on inbound ports and DTOs.
| Persistence        | GORM + Postgres | Productivity with migrations already defined. Models and repositories live in `internal/adapters/outbound/postgres/gorm`. Application services interact through repository ports for testability.
| Logging            | `log/slog` | Standard structured logging with context. Configured under `internal/platform/logging/slog`, injected into adapters and use cases via dependency wiring.
| Configuration      | Viper   | Unified config loading from env/files. Resides in `internal/platform/config/viper`, producing immutable settings structs consumed at startup.
| Telemetry          | OpenTelemetry | Cross-cutting instrumentation available to Gin, GORM, and background workers (`internal/platform/telemetry/opentelemetry`).

## 4. Request & Command Lifecycles

### 4.1 REST Request (e.g., `POST /areas`)
1. **Gin Router** (`internal/adapters/inbound/http/gin`) matches the route and invokes a handler.
2. **Handler** (`internal/adapters/inbound/http/handlers`) validates/binds payloads into DTOs and calls the relevant inbound port.
3. **Inbound Port** (`internal/ports/inbound/http`) defines the method signature implemented by an application service.
4. **Application Service** (`internal/app/area`) executes the use case, coordinating domain aggregates and outbound ports.
5. **Outbound Ports** – Service interacts with repositories (`internal/ports/outbound/repository`), queue, and notifier interfaces. Concrete adapters (e.g., `postgres/gorm`) perform data access.
6. **Presenter** (`internal/adapters/inbound/http/presenter`) shapes the application response into JSON.
7. **Middleware** handles logging, tracing, error translation before the response leaves the Gin server.

### 4.2 Trigger Processing Pipeline
1. External event hits a webhook endpoint or scheduled poller (inbound adapter).
2. Event translated into domain action event and pushed onto queue via `outbound/queue` port.
3. Worker adapter (`internal/adapters/inbound/worker`) pulls jobs, invokes automation application service.
4. Automation service evaluates AREA conditions, persists job state via repository ports, and dispatches reactions through notifier port.
5. Notifier adapter (webhook/mailer) executes reaction, logs delivery outcome.

## 5. Data Persistence Strategy

- **Schema Management** — `migrations/` directory contains idempotent SQL scripts. Startup sequence invokes GORM auto-migrations only for telemetry tables; domain schema is owned by migrations.
- **Repositories** — Each domain aggregate has a matching repository interface (e.g., `AreaRepository`, `UserRepository`). Implementations within `internal/adapters/outbound/postgres/gorm` translate between domain entities and persistence models. Transactions are scoped per use case via helpers in `internal/platform/database/gorm`.
- **Read Models** — For performance-sensitive endpoints (dashboards), consider read-optimized projections exposed via specialized outbound ports.

## 6. Configuration & Secrets

- `internal/platform/config/viper` reads layered config (defaults → `.env` → environment variables → remote secrets).
- Config structs fan out into sub-configs (HTTP, database, telemetry, OAuth providers).
- Secrets (OAuth tokens, webhook signing keys) are stored via `internal/ports/outbound/secrets` and implemented by adapters (e.g., HashiCorp Vault, AWS Secrets Manager) when required.

## 7. Logging & Observability

- **slog** is initialized once and passed via context. Middlewares enrich logs with request IDs and user claims.
- **Gin** middleware captures request metrics and spans through OpenTelemetry instrumentation.
- **GORM** instrumentation hooks emit SQL timings and errors.
- Telemetry exporters (OTLP, Prometheus) are configured in `internal/platform/telemetry/opentelemetry`.

## 8. Testing Strategy

- **Domain tests** live beside domain packages, using pure Go tests with no external dependencies.
- **Application tests** mock outbound ports to exercise use case flows.
- **Integration tests** within `test/integration` spin up Gin + GORM against ephemeral Postgres containers (via `docker-compose` or test harness) to validate real adapters.
- **Contract tests** ensure outbound adapters meet port expectations (e.g., repository behaviors).

## 9. Dependency Direction Checklist

- `cmd/` may import any internal package.
- `internal/app` may depend on `internal/domain`, `internal/ports`, and `internal/shared`.
- `internal/domain` only depends on the standard library and `internal/shared/errors` when necessary.
- `internal/ports` depends on domain DTOs/interfaces but not on adapters or platform.
- `internal/adapters` can depend on `internal/app`, `internal/ports`, `internal/platform`, and third-party libraries (Gin, GORM, OAuth2, Redis).
- `internal/platform` can depend on third-party tooling but must avoid depending on `internal/app` or `internal/adapters` to stay reusable.

## 10. Evolution Guidelines

- Introduce new services/actions/reactions by extending domain models first, then exposing them via application services and inbound adapters.
- Keep adapter implementations thin; push business validations into the application/domain layers.
- When adding infrastructure variations (e.g., alternate queue), create new adapter packages fulfilling existing ports.
- Document architectural decisions (ADR) in `docs/architecture/adr/` (create as needed) to capture trade-offs.

