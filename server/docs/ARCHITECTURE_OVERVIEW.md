# AREA Server - Architecture Overview

## Document Information

**Version**: 1.0
**Last Updated**: 2 November 2025
**Authors**: Gemini
**Target Audience**: Software Architects, Senior Developers, Tech Leads

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architectural Principles](#2-architectural-principles)
3. [High-Level Architecture](#3-high-level-architecture)
4. [Layer Architecture Deep Dive](#4-layer-architecture-deep-dive)
5. [Data Flow & Communication](#5-data-flow--communication)
6. [Concurrency Model](#6-concurrency-model)
7. [Database Design](#7-database-design)
8. [Dependency Management](#8-dependency-management)
9. [Feature Modules Architecture](#9-feature-modules-architecture)
10. [Cross-Cutting Concerns](#10-cross-cutting-concerns)

---

## 1. Executive Summary

### 1.1 Overview

AREA Server is the Go-based backend for the automation platform. It follows a **Layered Architecture** inspired by **Clean Architecture** and Domain-Driven Design (DDD) principles. The primary goal is to create a maintainable, testable, and scalable system by enforcing a strict separation of concerns.

- **Maintainable**: Clear boundaries between business logic and infrastructure.
- **Testable**: Each layer can be tested independently, with dependencies mocked.
- **Scalable**: The architecture supports adding new services and features with minimal impact on existing code.
- **Flexible**: Business logic is independent of frameworks like Gin or GORM.

### 1.2 Key Architectural Decisions

| Decision | Rationale |
|---|---|
| **Layered Architecture** | Separation of concerns, testability, maintainability. |
| **Domain-Driven Design (DDD)** | Focus on the core business domain, isolating it from infrastructure. |
| **Dependency Inversion** | High-level modules do not depend on low-level modules; both depend on abstractions. |
| **Repository Pattern** | Abstract data sources, enabling mocking for tests and flexibility in storage. |
| **Gin Web Framework** | High-performance, minimalist framework for building the HTTP API layer. |
| **GORM** | ORM library for PostgreSQL, simplifying database interactions. |
| **Viper & Dotenv** | Flexible configuration management from files and environment variables. |
| **Redis-based Job Queue** | Asynchronous execution of background tasks (e.g., reactions). |

### 1.3 Technology Stack

```
┌──────────────────────────────────────────────────┐
│                 Go Language 1.25.3                 │
├──────────────────────────────────────────────────┤
│  API Layer      │ Gin │ oapi-codegen              │
├──────────────────────────────────────────────────┤
│  Domain         │ Pure Go (no framework imports)  │
├──────────────────────────────────────────────────┤
│  Data Layer     │ GORM (PostgreSQL) │ go-redis    │
├──────────────────────────────────────────────────┤
│  Configuration  │ Viper │ gotenv                  │
├──────────────────────────────────────────────────┤
│  Logging        │ Zap                             │
└──────────────────────────────────────────────────┘
```

---

## 2. Architectural Principles

### 2.1 SOLID Principles

- **Single Responsibility Principle (SRP)**: Each package and struct has a clear, single purpose.
  - **App Handlers**: Orchestrate use cases.
  - **Domain Entities**: Represent core business objects.
  - **Repositories**: Manage persistence for a single aggregate.
- **Open/Closed Principle (OCP)**: The use of interfaces (`ports`) allows for extension (e.g., adding a new database implementation) without modifying existing application logic.
- **Liskov Substitution Principle (LSP)**: Concrete implementations of repository interfaces can be swapped without affecting the application layer.
- **Interface Segregation Principle (ISP)**: Interfaces are defined by the clients (the application layer) in the `ports` directory, ensuring they are minimal and focused.
- **Dependency Inversion Principle (DIP)**: High-level application logic depends on abstractions (interfaces in `ports`), not on concrete infrastructure implementations (in `adapters`).

### 2.2 Clean Architecture Principles

- **Independence**: The core domain logic in `internal/domain` is independent of frameworks, databases, and UI. It contains pure business rules.
- **Testability**: Each layer can be tested in isolation. Domain logic is tested without any infrastructure.
- **Dependency Rule**: Dependencies flow inwards. `adapters` depend on `app` and `domain`, and `app` depends on `domain`. The `domain` layer depends on nothing.

---

## 3. High-Level Architecture

### 3.1 Layered Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      ADAPTERS LAYER (Inbound)                    │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │                       HTTP (Gin)                          │   │
│  │ - Routes, Handlers, Request/Response marshaling           │   │
│  │ - Calls Application Services                              │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────▲────────────────────────────────┘
                                   │
                                   │
┌──────────────────────────────────┴────────────────────────────────┐
│                        APPLICATION LAYER                           │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │                  Application Services (app)                 │   │
│  │ - Orchestrates domain logic                               │   │
│  │ - Depends on Domain interfaces (ports)                    │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────▲────────────────────────────────┘
                                   │
                                   │
┌──────────────────────────────────┴────────────────────────────────┐
│                          DOMAIN LAYER                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │     Entities     │  │   Repositories   │  │      Ports       │  │
│  │  - User, Area    │  │   (Interfaces)   │  │   (Outbound)     │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
└──────────────────────────────────▲────────────────────────────────┘
                                   │
                                   │
┌──────────────────────────────────┴────────────────────────────────┐
│                     ADAPTERS LAYER (Outbound)                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │    PostgreSQL    │  │      Redis       │  │      Mailer      │  │
│  │ (GORM Repository)│  │   (Queue Impl)   │  │    (SendGrid)    │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Module Structure (`internal/`)

```
internal/
├── adapters/              # Infrastructure implementations
│   ├── inbound/http/      # Gin handlers and routing
│   └── outbound/          # External service clients
│       ├── mailer/        # Email sending implementations
│       ├── oauth/         # OAuth client logic
│       ├── postgres/      # GORM repository implementations
│       └── reaction/      # Reaction executors
│
├── app/                   # Application services
│   ├── about/
│   ├── area/
│   ├── auth/
│   └── ...
│
├── domain/                # Core business logic and entities
│   ├── area/
│   ├── user/
│   └── ...
│
├── platform/              # Shared infrastructure code
│   ├── config/
│   ├── database/
│   ├── logging/
│   └── ...
│
└── ports/                 # Interfaces for outbound communication
    ├── outbound/
    └── ...
```

---

## 4. Layer Architecture Deep Dive

### 4.1 Inbound Adapters (`adapters/inbound`)

- **Responsibilities**: Handle incoming requests (HTTP), parse and validate them, call the appropriate application service, and serialize the response.
- **Technology**: Gin framework.
- **Structure**: The `router` package wires up handlers. Handlers in `http` are responsible for the request/response lifecycle. OpenAPI spec generation (`oapi-codegen`) is used to ensure contract compliance.

### 4.2 Application Layer (`app`)

- **Responsibilities**: Orchestrate business logic. It acts as a mediator between the inbound adapters and the domain layer. It does not contain business rules itself.
- **Structure**: Each business feature (e.g., `auth`, `area`) has its own application service/handler. These services depend on interfaces defined in the `ports` directory.

### 4.3 Domain Layer (`domain`)

- **Responsibilities**: Define core business entities, value objects, and business rules. This layer is the heart of the application.
- **Structure**: Contains pure Go structs and functions. It has no dependencies on any other layer in the project, ensuring its independence.

### 4.4 Ports Layer (`ports`)

- **Responsibilities**: Define the interfaces (contracts) for all outbound communication. This includes database access, message queues, external APIs, etc.
- **Structure**: The application layer depends on these interfaces, and the outbound adapters implement them. This follows the Dependency Inversion Principle.

### 4.5 Outbound Adapters (`adapters/outbound`)

- **Responsibilities**: Implement the interfaces defined in the `ports` layer. This is where all the interaction with external systems happens.
- **Structure**:
  - `postgres/`: GORM-based implementations of repository interfaces.
  - `mailer/`: Implementations for sending emails (e.g., SendGrid, logger).
  - `reaction/`: Concrete executors for AREA reactions (e.g., posting to Slack, creating a GitHub issue).

### 4.6 Platform Layer (`platform`)

- **Responsibilities**: Provide shared, cross-cutting infrastructure concerns.
- **Structure**: Contains packages for configuration (`viper`), database connections (`postgres`), logging (`zap`), and HTTP server setup (`httpserver`).

---

## 5. Data Flow & Communication

### User Registration Flow (End-to-End)

1.  **HTTP Request**: `POST /v1/users` hits the Gin router.
2.  **Inbound Adapter**: The `auth` handler in `adapters/inbound/http` parses the JSON request into a `RegisterUserRequest` struct.
3.  **Application Service**: The handler calls `app.auth.Service.Register()`.
4.  **Domain Logic**: The `Register` service validates the input, hashes the password, and creates a `user.User` domain entity.
5.  **Outbound Port**: The service calls the `UserRepository.Create()` interface method.
6.  **Outbound Adapter**: The `postgres.userRepo` implementation of the repository inserts the user record into the database.
7.  **Response**: The flow unwinds, and the HTTP handler returns a `202 Accepted` response.
8.  **Async Task**: An email verification token is created and an email is sent via the `Mailer` port/adapter.

---

## 6. Concurrency Model

- **HTTP Requests**: Each incoming request is handled in its own goroutine by the Gin web server.
- **Background Jobs**: AREA reactions are executed asynchronously by background workers.
  - A Redis-based job queue (`internal/platform/queue/redis`) is used to enqueue jobs.
  - A pool of workers (`internal/app/automation/worker.go`) consumes jobs from the queue.
- **Scheduled & Polling Actions**: `TimerScheduler` and `PollingRunner` run in dedicated background goroutines, periodically checking for due actions and enqueuing jobs.

---

## 7. Database Design

- **ORM**: GORM is used for database interaction.
- **Migrations**: Database schema changes are managed via SQL migration files in the `/migrations` directory. This ensures version-controlled, repeatable schema deployments. Each migration has a `.up.sql` and a `.down.sql` file.
- **Models**: GORM models are defined within the `postgres` adapter packages (e.g., `internal/adapters/outbound/postgres/auth/models.go`). These models are kept separate from the domain entities and include `toDomain()` methods for conversion.

---

## 8. Dependency Management

- **Go Modules**: All project dependencies are managed via `go.mod` and `go.sum`.
- **Dependency Injection**: Dependencies are constructed and injected manually in `cmd/server/main.go`. This approach, while verbose, is explicit and easy to follow. There is no dependency injection framework in use.
- **Makefile**: Provides convenient scripts for building, testing, and running the application.

---

## 9. Feature Modules Architecture

- **`auth`**: Manages user registration, login, sessions, password changes, and OAuth2 integrations.
- **`area`**: Core logic for creating, updating, and executing automations (AREAs).
- **`components`**: Serves the catalog of available action and reaction components.
- **`monitoring`**: Exposes endpoints for observing job and delivery log history.
- **`about`**: Serves the `/about.json` metadata endpoint.

---

## 10. Cross-Cutting Concerns

- **Configuration**: Managed by `Viper`, loading from `config.yaml` and overriding with environment variables. Secrets are loaded from `.env` files.
- **Logging**: Structured logging is implemented using `Zap`. A global logger is configured in `main.go`.
- **Error Handling**: Errors are propagated up the call stack and wrapped with context using `fmt.Errorf` and `%w`. HTTP handlers are responsible for mapping service-layer errors to appropriate HTTP status codes.
- **Rate Limiting**: A middleware (`internal/platform/httpmiddleware/ratelimit`) provides rate limiting for HTTP requests based on session or IP.
