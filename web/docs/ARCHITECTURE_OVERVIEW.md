# AREA Web - Architecture Overview

## Document Information

**Version**: 1.0
**Last Updated**: 1 November 2025
**Authors**: Yanis Kernoua (<yanis.kernoua@epitech.eu>)
**Target Audience**: Software Architects, Senior Developers, Tech Leads

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architectural Principles](#2-architectural-principles)
3. [High-Level Architecture](#3-high-level-architecture)
4. [Layer Architecture Deep Dive](#4-layer-architecture-deep-dive)
5. [Data Flow & Communication](#5-data-flow--communication)
6. [State Management Architecture](#6-state-management-architecture)
7. [Navigation Architecture](#7-navigation-architecture)
8. [Dependency Management](#8-dependency-management)
9. [Feature Modules Architecture](#9-feature-modules-architecture)
10. [Cross-Cutting Concerns](#10-cross-cutting-concerns)
11. [Design Patterns & Best Practices](#11-design-patterns--best-practices)
12. [Architecture Decision Records](#12-architecture-decision-records)

---

## 1. Executive Summary

### 1.1 Overview

AREA Web is a Next.js application that powers the browser experience for the automation platform. It combines **Next.js App Router** server components with **React Query** and **OpenAPI-generated clients** to deliver a typed, resilient front end that shares business contracts with the mobile and server stacks.

The architecture prioritizes:

- **Performance**: Server-first rendering with streaming and granular caching
- **Developer Velocity**: Typed APIs, feature folders, and composable UI primitives
- **Reliability**: Predictable error handling, automatic session refresh, and mockable data sources
- **International Reach**: Localization and theming built into the routing layer

### 1.2 Key Architectural Decisions

| Decision                              | Rationale                                                             |
| ------------------------------------- | --------------------------------------------------------------------- |
| **Next.js App Router**                | Server-first rendering, nested layouts, edge compatibility            |
| **React Query**                       | Declarative data fetching, cache orchestration, request deduplication |
| **OpenAPI-generated client layer**    | Shared contracts with backend, compile-time safety                    |
| **Feature-oriented folder structure** | Keeps domains cohesive, reduces cross-feature coupling                |
| **Zod-based environment validation**  | Early failure for misconfigured deployments                           |
| **next-intl localization**            | Route-aware translations, fallback handling                           |
| **Tailwind + Radix-based UI system**  | Accessible primitives with consistent theming                         |

### 1.3 Technology Stack

```
┌──────────────────────────────────────────────────────┐
│                Next.js 15 (App Router)               │
├──────────────────────────────────────────────────────┤
│   UI Layer    │ React 19 │ Tailwind CSS 4 │ Radix UI  │
├──────────────────────────────────────────────────────┤
│   Data Layer  │ @tanstack/react-query │ OpenAPI SDK  │
│               │ Custom fetch client │ Mock runtime   │
├──────────────────────────────────────────────────────┤
│   Utilities   │ TypeScript 5 │ Zod │ next-intl       │
├──────────────────────────────────────────────────────┤
│   Tooling     │ ESLint 9 │ Vitest 2 │ Turbopack      │
└──────────────────────────────────────────────────────┘
```

---

## 2. Architectural Principles

### 2.1 Composition & Separation of Concerns

- **Server components render data-bound shells** while **client components handle interactivity** (`'use client'` directive)
- Domain types live in `@/lib/api/contracts`, ensuring UI components do not depend on transport DTOs
- Hooks encapsulate side effects (`useAreasQuery`, `useCreateAreaMutation`) so UI remains declarative

```tsx
const { data: areas, isPending } = useAreasQuery({
  staleTime: 60_000,
  meta: { redirectOn401: true }
})
```

### 2.2 Predictable Error Surfaces

- All API calls resolve to `ApiError` instances; components inspect `error.status` to branch
- Auth expirations trigger redirect via `QueryProvider` without leaking transport errors to the view
- Server components wrap redirects (see `src/app/dashboard/layout.tsx`) to prevent unauthorized rendering

### 2.3 Extensibility

- OpenAPI layer isolates transport concerns, enabling mock data sources and future protocol changes
- Feature folders (`components/areas`, `lib/api/openapi/areas`) keep additions localized
- Utility packages (`@/lib/utils`, `@/components/ui`) abstract repeated patterns without framework lock-in

---

## 3. High-Level Architecture

```
┌─────────────────────────────┐
│ Browser (React clients)     │
│  - Feature components       │
│  - Forms, tables, modals    │
└──────────────▲──────────────┘
               │
┌──────────────┴──────────────┐
│ Next.js App Router           │
│  - Server layouts            │
│  - Route handlers (app/api)  │
│  - Streaming & caching       │
└──────────────▲──────────────┘
               │
┌──────────────┴──────────────┐
│ API Access Layer             │
│  - OpenAPI clients           │
│  - React Query cache         │
│  - apiFetch (client/server)  │
└──────────────▲──────────────┘
               │
┌──────────────┴──────────────┐
│ Backend Services             │
│  - AREA REST API             │
│  - logo.dev proxy (app/api)  │
└─────────────────────────────┘
```

- **Server components** perform authentication checks and preload critical data
- **Client components** subscribe to React Query caches for real-time updates
- **Edge and serverless route handlers** proxy external APIs (`src/app/api/logo/route.ts`)

---

## 4. Layer Architecture Deep Dive

### 4.1 Presentation Layer (`src/app`, `src/components`)

- **Responsibilities**: Layouts, page shells, interactive widgets, onboarding flows
- **Rules**:
  - ✅ Can import feature hooks, contracts, and UI primitives
  - ❌ Must not call `fetch` directly—always go through hook/client layer
  - ✅ Use `next-intl` for user-facing strings
- **Key Constructs**:
  - Layout guards (`dashboard/layout.tsx`) enforce auth on the server
  - Feature widgets (`areas/create-area-modal.tsx`) encapsulate complex workflows

### 4.2 Domain & View-Model Layer (`src/lib/api/contracts`, `src/components/**`)

- **Responsibilities**: Domain models (`Area`, `Service`), adapters, view-specific transformers
- **Contracts**: Distinguish DTOs (`CreateAreaRequestDTO`) from internal shapes (`Area`)
- **Rules**:
  - ✅ Transformations happen in `adapter.ts` files
  - ✅ Keep mutations optimistic-friendly (return normalized entities)

### 4.3 Data Access Layer (`src/lib/api`)

- **Responsibilities**: Typed API clients, HTTP wrappers, runtime configuration, mocks
- **Submodules**:
  - `http/client.ts` / `http/server.ts`: central fetch wrappers with refresh & cookie handling
  - `openapi/*`: generated endpoints, query/mutation builders, React hooks
  - `mock/*`: deterministic fixtures for `NEXT_PUBLIC_API_MODE=mock`
- **Rules**:
  - ✅ Use `apiConfig.buildUrl` to respect proxy rewrites
  - ✅ Return `ApiError` on failure; never throw raw `Response`
  - ❌ No direct UI dependencies

---

## 5. Data Flow & Communication

1. **Server layout** (e.g., `dashboard/layout.tsx`) invokes `currentUserServer()` to gate the route.
2. **Client component** calls a hook such as `useAreasQuery()`, which maps to:
   - Query configuration in `openapi/areas/queries.ts`
   - HTTP call via `apiFetchClient`
3. **React Query** caches the result under structured keys (`areasKeys.list()`).
4. **Mutations** invalidate query caches to keep views in sync:

```tsx
const createArea = useCreateAreaMutation({
  onSuccess: () => toast.success(t('create.success'))
})
createArea.mutate(payload)
```

5. **Error handling** flows through `ApiError`, allowing UI to show toasts or redirects.
6. **Mock runtime** short-circuits requests when `NEXT_PUBLIC_API_MODE=mock`.

---

## 6. State Management Architecture

- **React Query** orchestrates remote data, retries, and background refresh.
  - Default stale time: 30 seconds (`QueryProvider`)
  - Automatic 401 redirect when queries opt-in via `meta.redirectOn401`
- **Local component state** handles ephemeral UI (combobox selections, modals).
- **Context providers**:
  - `QueryProvider`: supplies query client with auth-aware error handling
  - `ThemeProvider`: controls dark/light modes (`next-themes`)
  - `NextIntlClientProvider`: exposes translations to client components
- **Session Refresh**: `apiFetchClient` retries 401 responses by POSTing `/auth/refresh`.

---

## 7. Navigation Architecture

- **App Router** structure mirrors product areas:
  - `(public)/` for marketing routes (`/`, `/about`, `/explore`)
  - `login`, `register`, `oauth`, `oauth2` for onboarding
  - `dashboard` with nested subroutes (`/links`, `/profile`, `/admin`)
- **Guarding Strategies**:
  - Server redirects via `redirect('/login')` prevent flashing protected content
  - Client-side checks leverage `meta.redirectOn401` to reroute after token expiry
- **Breadcrumbs & sidebar** derive from path segments (`DynamicBreadcrumb`).
- **API routes** in `app/api/*` expose lightweight proxies without leaving the app router.

---

## 8. Dependency Management

- **Package Manager**: npm (lockfile checked-in). Scripts in `web/package.json`.
- **Path Aliases**: `@/` root alias configured in `tsconfig.json`.
- **ESLint**: Custom config (`eslint.config.mjs`) with React, Next, React Query rules.
- **Type Safety**: `tsconfig.json` enables strict mode; `npm run typecheck` must pass in CI.
- **Build Tooling**: Turbopack for dev/build; Vitest configured for unit (`vitest.config.ts`) and e2e (`vitest.e2e.config.ts`) suites.

---

## 9. Feature Modules Architecture

| Domain                  | UI Entry Points                                            | Data Access                              |
| ----------------------- | ---------------------------------------------------------- | ---------------------------------------- |
| **Authentication**      | `components/authentication/*`, `/login`, `/register`       | `lib/api/openapi/auth`                   |
| **Services**            | `components/services/*`, `/dashboard`                      | `lib/api/openapi/services`               |
| **Areas (Automations)** | `components/areas/*`, `/dashboard/links`                   | `lib/api/openapi/areas`, `components`    |
| **Accounts**            | `/dashboard/profile`, `components/dashboard/user-dropdown` | `lib/api/openapi/users`                  |
| **Marketing**           | `(public)/*`                                               | `lib/api/openapi/about` (mocked content) |

- Each feature owns:
  - OpenAPI hooks, query keys, and adapters
  - UI components with tests under the same folder
  - Messages in `messages/en.json` (namespaced keys)
- Shared UI primitives live in `components/ui` and must remain stateless.

---

## 10. Cross-Cutting Concerns

- **Internationalization**: `next-intl` provides locale-scoped translations; wrap tests with `NextIntlClientProvider`.
- **Theming**: `ThemeProvider` syncs with system preferences; components rely on Tailwind tokens.
- **Accessibility**: Radix UI primitives supply keyboard support; ensure descriptive labels (`aria-label`, `role`).
- **Security**:
  - CSRF tokens accepted by `apiFetchClient`
  - Cookies forwarded by `apiFetchServer` using `next/headers`
  - OAuth flows persist state via `lib/auth/oauth`
- **Error Reporting**: Toast notifications via `sonner`; avoid silent failures.
- **Environment Safety**: `src/env.ts` validates all required variables at startup; missing config aborts the build.

---

## 11. Design Patterns & Best Practices

- **Server-first data loading**: Prefer server components for initial hydration (`currentUserServer`).
- **Hook encapsulation**: Keep React Query logic in feature-specific hooks; never inline `useQuery`.
- **Optimistic UI**: Mutations invalidate caches and may return optimistic payloads (`areasMutations.create`).
- **Composable UI**: Use `components/ui/*` primitives to maintain consistency and reduce CSS drift.
- **Test strategy**:
  - Unit & integration: Vitest + Testing Library (`npm run test:unit`)
  - E2E-like scenarios: `web/e2e` renders pages with providers
- **Error boundaries**: Handle `ApiError` status codes explicitly to avoid blank states.

---

## 12. Architecture Decision Records

### ADR-001: Adopt Next.js App Router

**Status**: Accepted
**Date**: 2025-09
**Deciders**: Web Platform Team

**Context**: Need server-driven routing with streaming, nested layouts, and co-located data-fetching for a complex dashboard.

**Decision**: Use Next.js 15 App Router with server components and route handlers.

**Consequences**:
✅ Simplified auth gating and data preloading
✅ Built-in edge/serverless deployment options
❌ Learning curve for server vs. client component boundaries
❌ Requires strict separation to avoid server-only imports in client code

### ADR-002: React Query for Remote State

**Status**: Accepted
**Date**: 2025-09
**Deciders**: Web Platform Team

**Context**: Need cache-aware data fetching with automatic retries and request deduplication across interactive widgets.

**Decision**: Standardize on `@tanstack/react-query` with a shared provider.

**Consequences**:
✅ Predictable caching, refetching, and background updates
✅ Consistent error handling (401 redirect, toast integration)
❌ Additional provider boilerplate and hook discipline required

### ADR-003: Generate OpenAPI Client

**Status**: Accepted
**Date**: 2025-09
**Deciders**: Web Platform Team

**Context**: Ensure the web client stays in lockstep with backend contract changes without manual DTO maintenance.

**Decision**: Use code-generated clients under `src/lib/api/openapi` with adapters to domain models.

**Consequences**:
✅ Type-safe API layer shared with mobile/server teams
✅ Easier mocking via consistent interfaces
❌ Requires regeneration when contracts evolve
❌ Verbose folder structure, mitigated by feature grouping

### ADR-004: Mockable API Runtime

**Status**: Accepted
**Date**: 2025-10
**Deciders**: Web Platform Team

**Context**: Local development and demos must work without a live backend.

**Decision**: Introduce `apiRuntime` flag and mock implementations in `src/lib/api/mock`.

**Consequences**:
✅ Developers can explore flows offline
✅ CI gains deterministic fixtures
❌ Must keep mock data updated with real responses
❌ Potential divergence if mocks drift from production API

### ADR-005: Tailwind & Radix-based Design System

**Status**: Accepted
**Date**: 2025-09
**Deciders**: Web Platform Team

**Context**: Need an accessible, themeable component library that matches branding and accelerates feature work.

**Decision**: Compose UI from Tailwind CSS tokens, Radix primitives, and project-specific wrappers (`components/ui`).

**Consequences**:
✅ Consistent styling with dark-mode support out of the box
✅ Accessibility handled by Radix under the hood
❌ Requires discipline to avoid bespoke CSS
❌ Token updates propagate widely; changes must be coordinated

---

**Revision History**

- v1.0 (2025-11-01): Initial architecture documentation for the web client
