# AREA Server - Developer Documentation

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Project Structure](#3-project-structure)
4. [Getting Started](#4-getting-started)
5. [Core Concepts](#5-core-concepts)
6. [Adding a New Reaction](#6-adding-a-new-reaction)
7. [Database Migrations](#7-database-migrations)
8. [API & Code Generation](#8-api--code-generation)
9. [Best Practices](#9-best-practices)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Project Overview

### 1.1 Purpose

The AREA Server is the backend application responsible for all business logic, including user management, service integrations, and the orchestration of automations (AREAs). It exposes a REST API consumed by the web and mobile clients.

### 1.2 Technology Stack

- **Language**: Go 1.25.3
- **Web Framework**: Gin
- **ORM**: GORM (for PostgreSQL)
- **Configuration**: Viper
- **Logging**: Zap
- **Job Queue**: Redis Streams
- **API Specification**: OpenAPI 3.0
- **Build & Task Runner**: Make

--- 

## 2. Architecture

The server follows a **Layered Architecture** inspired by Clean Architecture principles. This separates the code into distinct layers, each with a specific responsibility.

```
┌─────────────────────────────────────────┐
│         ADAPTERS (Inbound/Outbound)     │
│  (HTTP Handlers, DB Repos, Mailers)    │
└─────────────────────────────────────────┘
                  ↓↑
┌─────────────────────────────────────────┐
│          APPLICATION (app)              │
│  (Use Case Orchestration)              │
└─────────────────────────────────────────┘
                  ↓↑
┌─────────────────────────────────────────┐
│          DOMAIN                         │
│  (Business Entities & Rules)           │
└─────────────────────────────────────────┘
```

- **Domain**: Contains the core business logic and types. It is completely independent of any framework.
- **Application (`app`)**: Orchestrates the domain logic to perform use cases. It knows nothing about HTTP or SQL.
- **Ports**: Defines the interfaces for outbound communication (e.g., `UserRepository`). The application layer depends on these interfaces.
- **Adapters**: Implements the interfaces defined in `ports`. This is where all infrastructure-specific code lives (e.g., Gin handlers, GORM repositories).

For a more detailed explanation, refer to `ARCHITECTURE_OVERVIEW.md`.

---

## 3. Project Structure

```
server/
├── api/                     # OpenAPI specifications
├── bin/                     # Compiled binaries (ignored by git)
├── cmd/server/              # Main application entry point
├── config/                  # Default configuration files
├── internal/                # All application source code
│   ├── adapters/            # Infrastructure implementations
│   │   ├── inbound/http/    # HTTP handlers and routing
│   │   └── outbound/        # Database repos, external clients
│   ├── app/                 # Application services (use cases)
│   ├── domain/              # Core business models and logic
│   ├── platform/            # Shared platform code (logging, db conn)
│   └── ports/               # Interfaces for outbound adapters
├── migrations/              # SQL database migrations
├── scripts/                 # Helper scripts
├── .env.example             # Environment variable template
├── Dockerfile               # Container definition
├── go.mod                   # Go module dependencies
└── Makefile                 # Build, test, and run commands
```

---

## 4. Getting Started

### 4.1 Prerequisites

- Go 1.25.3 or later
- Docker and Docker Compose
- `make`
- `psql` (for interacting with the database)

### 4.2 Environment Setup

1.  **Copy Environment File**: Create a `.env` file from the example.

    ```bash
    cp .env.example .env
    ```

2.  **Configure Secrets**: Edit the `.env` file and fill in the required secrets, especially:
    - `DATABASE_URL` or `DATABASE_USER`/`DATABASE_PASSWORD`
    - `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `PASSWORD_PEPPER`
    - `IDENTITY_ENCRYPTION_KEY` (must be a base64-encoded 32-byte key)
    - Any OAuth provider credentials you intend to use.

3.  **Start Database**: Run the local PostgreSQL and Redis instances.

    ```bash
    docker-compose up -d database redis
    ```

4.  **Apply Migrations**: Apply the latest database schema.

    ```bash
    make migrate-up
    ```

### 4.3 Running the Server

Use the `Makefile` for common development tasks.

```bash
# Run the server with hot-reloading
make run

# Build a production binary
make build

# Run tests
make test

# Run linter
make lint
```

The server will be available at `http://localhost:8080`.

---

## 5. Core Concepts

### 5.1 Dependency Injection

Dependencies are constructed and injected manually in `cmd/server/main.go`. This makes the dependency graph explicit and easy to trace. When adding a new service or repository, you will need to update this file to wire it into the application.

### 5.2 Configuration

Configuration is loaded by `Viper` from `config/config.yaml` and can be overridden by environment variables. Secrets are loaded from the `.env` file. See `internal/platform/config/viper/` for details.

### 5.3 Error Handling

- Errors are propagated up the call stack using `fmt.Errorf` with the `%w` verb to wrap underlying errors.
- Service layers return specific, exported error variables (e.g., `auth.ErrInvalidCredentials`) when a caller needs to act on the error type.
- HTTP handlers are responsible for mapping errors to appropriate status codes.

### 5.4 Background Jobs

AREA reactions are processed asynchronously. The `ExecutionPipeline` creates jobs which are pushed to a Redis stream. The `automation.Worker` consumes these jobs and uses a `CompositeReactionExecutor` to dispatch them to the correct handler.

---

## 6. Adding a New Reaction

This example shows how to add a new reaction for the **GitHub** service.

#### Step 1: Define the Component in a Migration

Create a new SQL migration file in `/migrations` to define the component in the database.

```sql
-- migrations/0000XX_seed_my_new_reaction.up.sql
WITH provider AS (
    SELECT id FROM "service_providers" WHERE name = 'github'
)
INSERT INTO "service_components" (...) VALUES (...);
```

Define the component's parameters in the `metadata` JSONB field. This metadata drives the UI for configuring the reaction.

#### Step 2: Create the Reaction Executor

Create a new package under `internal/adapters/outbound/reaction/`, for example, `internal/adapters/outbound/reaction/github/my_reaction.go`.

Implement the `area.ComponentReactionHandler` interface:

```go
package github

// ... imports

type MyReactionExecutor struct { /* dependencies */ }

func NewMyReactionExecutor(...) *MyReactionExecutor { /* ... */ }

func (e *MyReactionExecutor) Supports(component *componentdomain.Component) bool {
    return component.Provider.Name == "github" && component.Name == "my_new_reaction"
}

func (e *MyReactionExecutor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
    // 1. Parse and validate parameters from link.Config.Params
    // 2. Fetch the user's GitHub identity
    // 3. Refresh the OAuth token if necessary
    // 4. Make the API call to GitHub
    // 5. Return the result and any error
    return outbound.ReactionResult{}, nil
}
```

#### Step 3: Register the Executor

In `cmd/server/main.go`, instantiate your new executor and add it to the `CompositeReactionExecutor`.

```go
// cmd/server/main.go

// ...
import githubexecutor "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/reaction/github"
// ...

func run() error {
    // ...
    reactionHandlers := []areaapp.ComponentReactionHandler{
        httpreaction.Executor{ /* ... */ },
        // ... other executors
    }

    if oauthManager != nil {
        // ...
        myReactionExecutor := githubexecutor.NewMyReactionExecutor( /* dependencies */ )
        if myReactionExecutor != nil {
            reactionHandlers = append(reactionHandlers, myReactionExecutor)
        }
    }

    reactionExecutor := areaapp.NewCompositeReactionExecutor(nil, logger, reactionHandlers...)
    // ...
}
```

---

## 7. Database Migrations

- Use `make migrate-create name=your_migration_name` to create new up/down migration files.
- Write idempotent SQL in the migration files.
- Apply migrations with `make migrate-up`.
- Roll back migrations with `make migrate-down`.

---

## 8. API & Code Generation

The REST API contract is defined in `api/openapi.yaml`. The Go server models and interfaces are generated from this file.

To regenerate the code after changing the OpenAPI spec:

```bash
make generate
```

This command uses `oapi-codegen` (defined in `tools.go`) to update `internal/adapters/inbound/http/openapi/generated.gen.go`.

---

## 9. Best Practices

- **Code Style**: Always format your code with `gofmt` or `goimports`.
- **Commit Messages**: Follow the Conventional Commits specification as seen in the git history (`feat(scope): summary`).
- **Testing**: Write unit tests for new logic. Use `make test` to run the full suite.
- **Error Handling**: Wrap errors with context. Handle errors once; don't log and return.
- **Documentation**: Keep `AGENTS.md` and other documentation up-to-date with any changes to the development process.

---

## 10. Troubleshooting

- **`make run` fails with database errors**: Ensure your PostgreSQL container is running (`docker-compose ps`) and that the credentials in your `.env` file are correct.
- **`401 Unauthorized` on all authenticated endpoints**: Your session cookie might be invalid or expired. Try logging in again.
- **OAuth flow fails**: Double-check that the `redirectURI` in your `config.yaml` matches what is configured in the OAuth provider's developer console.
