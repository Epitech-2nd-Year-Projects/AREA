# Configuration Guide

This document explains how the AREA server loads configuration, the expected files, and how to extend settings for new features. The system combines a versioned `config.yaml` for non-sensitive defaults with an `.env` file for credentials and per-environment overrides.

## Configuration Sources

1. **Base YAML**: `config/config.yaml` holds environment-agnostic defaults: server ports, timeouts, logging format, feature toggles. Commit this file to version control.
2. **Environment Variables**: Any field can be overridden using environment variables (e.g., `AREA__SERVER__HTTP__PORT=9443`). This is the preferred mechanism in CI/CD or containerized deployments.
3. **Secrets (.env)**: `.env` (ignored by git) supplies sensitive values such as database passwords or OAuth secrets during local development. In production, replace this with your secret manager of choice.

Viper merges the sources in that order: YAML → environment variables → `.env`. Later sources overwrite earlier ones, giving you deterministic overrides per environment.

## File Layout

```
config/
  config.yaml            # user-provided configuration --> copy from config.example.yaml
  config.example.yaml    # template with safe defaults
.env                     # secrets for local development --> copy from .env.example
.env.example             # template with safe defaults
```

### `config/config.yaml`

Copy `config/config.example.yaml` into `config/config.yaml` and tailor the values for your environment (ports, telemetry exporters, queue driver). Keep this file in version control for each environment branch or provide per-env variants via deployment tooling.

### `.env`

Duplicate `.env.example` into `.env` and fill in secrets:
- Database user/password or full connection URL
- JWT signing keys and password pepper
- OAuth client IDs/secrets
- API keys for mailer/notifier providers

> ⚠️ `.env` must never be committed. Add environment-specific secret management in production

## Configuration Structure

The configuration hydrates the following nested structure (shown in YAML form for readability):

```yaml
app:
  name: AREA Server
  environment: production
  baseURL: https://api.area.example

server:
  http:
    host: 0.0.0.0
    port: 8080
    readTimeout: 15s
    writeTimeout: 15s
    idleTimeout: 60s
    cors:
      allowedOrigins: ["https://app.area.example"]
      allowedMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      allowedHeaders: ["Authorization", "Content-Type"]
      allowCredentials: true
  telemetry:
    tracing:
      enabled: true
      exporter: otlp
      endpoint: http://otel-collector:4317
    metrics:
      enabled: true
      exporter: prometheus
      endpoint: :9464
    samplingRatio: 0.2

database:
  driver: postgres
  host: postgres
  port: 5432
  name: area
  sslMode: disable
  maxOpenConns: 25
  maxIdleConns: 25
  connMaxLifetime: 30m

logging:
  level: info
  format: json
  includeCaller: false
  defaultFields:
    service: area-server

queue:
  driver: redis
  redis:
    addr: redis:6379
    db: 0
    consumerGroup: area-workers
    stream: area-jobs

notifier:
  webhook:
    timeout: 10s
    maxRetries: 5
    retryBackoff: 2s
  mailer:
    provider: sendgrid
    fromEmail: noreply@area.example
    sandboxMode: false

secrets:
  provider: dotenv
  path: .env

oauth:
  allowedProviders: ["google", "github"]
  providers:
    google:
      clientIDEnv: GOOGLE_OAUTH_CLIENT_ID
      clientSecretEnv: GOOGLE_OAUTH_CLIENT_SECRET
      redirectURI: https://api.area.example/oauth/google/callback
      scopes: ["email", "profile"]

security:
  jwt:
    issuer: area-api
    accessTokenTTL: 15m
    refreshTokenTTL: 720h
  password:
    minLength: 12
    pepperEnv: PASSWORD_PEPPER

servicesCatalog:
  refreshInterval: 5m
  bootstrapFile: config/services.yaml
```

## Environment Variable Overrides

Viper supports nested overrides by replacing dots with double underscores and uppercasing:

```bash
export AREA__SERVER__HTTP__PORT=8443
export AREA__LOGGING__LEVEL=debug
```

This pattern works well with container orchestrators (Docker, Kubernetes) and CI pipelines.

## Managing Secrets per Environment

- **Local Development**: `.env` file with developer-specific credentials. Use tools like `direnv` to auto-load.
- **CI/CD**: Inject environment variables directly in the pipeline (`AREA__DATABASE__HOST`, `GOOGLE_OAUTH_CLIENT_SECRET`).
- **Production**: Configure `secrets.provider` to use a vault adapter and populate secrets at runtime (`internal/ports/outbound/secrets`).

## Bootstrapping Steps

1. Copy examples:
   ```bash
   cp config/config.example.yaml config/config.yaml
   cp .env.example .env
   ```
2. Update `config/config.yaml` for your local setup (ports, telemetry endpoints).
3. Fill `.env` with your credentials.
4. Start the server (`make run`).

## Extending Configuration

When adding new features that require configuration:

1. Extend the configuration struct in `internal/platform/config/viper`.
2. Add defaults to `config/config.example.yaml` with sensible non-secret values.
3. Document required secrets in `.env.example`.
4. Ensure new values can be overridden via environment variables.

## Validation & Fail Fast

On startup, the config loader should validate:
- Durations (`readTimeout`, `retryBackoff`) parse correctly.
- Required secrets are present (e.g., JWT keys in non-development environments).
- Enum-like fields (logging level, telemetry exporter) match supported values.

Failing fast prevents the server from running with incomplete configuration, improving reliability.

## Sample Deployment Matrix

| Environment | Config Source                         | Notes |
|-------------|----------------------------------------|-------|
| Local Dev   | `config.yaml` + `.env`                 | Telemetry exporters disabled or local collector.
| Staging     | `config.yaml` + CI env vars            | Secrets injected via CI, telemetry enabled.
| Production  | `config.yaml` + secrets manager adapter| High availability settings (timeouts, queue).

Keep `config.yaml` small and declarative. Logic belongs in the config loader or application services, not in the YAML files.
