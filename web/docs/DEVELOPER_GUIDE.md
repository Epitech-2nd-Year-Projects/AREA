# AREA Web - Developer Documentation

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Project Structure](#3-project-structure)
4. [Getting Started](#4-getting-started)
5. [Core Concepts](#5-core-concepts)
6. [Adding New Features](#6-adding-new-features)
7. [State Management](#7-state-management)
8. [Navigation](#8-navigation)
9. [API Integration](#9-api-integration)
10. [Design System](#10-design-system)
11. [Best Practices](#11-best-practices)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Project Overview

### 1.1 Purpose

AREA Web delivers the browser experience for creating and managing automations (AREAs). The application mirrors mobile capabilities while showcasing additional dashboard and administration tools.

### 1.2 Technology Stack

- **Framework**: Next.js 15 (App Router, Turbopack)
- **Language**: TypeScript 5.x
- **UI Library**: React 19.x with Tailwind CSS 4 and Radix UI primitives (ShadCn)
- **State Management**: @tanstack/react-query + local component state
- **Localization**: next-intl
- **Forms & Validation**: Custom logic + Zod schemas (env, API payloads)
- **API Layer**: OpenAPI-generated SDK, `apiFetchClient` / `apiFetchServer`
- **Testing**: Vitest 2.x, Testing Library, jsdom

### 1.3 Key Features

- Secure authentication with email/password and Google OAuth
- Service catalog browsing and subscription management
- AREA creation via guided modal workflow with component configuration
- Responsive dashboards with protected routes and breadcrumbs
- Internationalized marketing pages and user flows

---

## 2. Architecture

### 2.1 Layered Application Model

```
┌────────────────────────────────────────┐
│ Presentation (app/, components/)       │
│  - Server layouts, client widgets      │
│  - next-intl translations, theming     │
└────────────────────────────────────────┘
                 ↓↑
┌────────────────────────────────────────┐
│ Domain & View Models (lib/api/contracts│
│  - Domain types, adapters              │
│  - Local utilities (lib/utils)         │
└────────────────────────────────────────┘
                 ↓↑
┌────────────────────────────────────────┐
│ Data Layer (lib/api)                   │
│  - OpenAPI clients & hooks             │
│  - Mock runtime, HTTP clients          │
└────────────────────────────────────────┘
```

- Server components perform auth checks and coarse data fetching.
- Client components subscribe to React Query caches and drive interactivity.
- `lib/api/mock` enables offline development and deterministic testing.

### 2.2 Execution Contexts

- **Server-only modules**: Marked with `'server-only'` (e.g., `lib/api/http/server.ts`).
- **Client components**: Opt-in with `'use client'`; avoid importing server-only APIs.
- **Shared utilities**: Reside in `lib` and must remain context-agnostic.

---

## 3. Project Structure

```text
web/
├── src/
│   ├── app/                 # App Router routes, layouts, route handlers
│   │   ├── (public)/        # Marketing pages
│   │   ├── dashboard/       # Authenticated workspace
│   │   ├── api/             # Serverless API proxies (logo.dev)
│   │   └── login|register   # Auth flows
│   ├── components/          # Feature and UI components
│   │   ├── areas/           # AREA creation widgets
│   │   ├── services/        # Service catalog components
│   │   └── ui/              # Design system primitives (Tailwind + Radix)
│   ├── hooks/               # Shared hooks (`use-mobile`, etc.)
│   ├── lib/
│   │   ├── api/             # HTTP clients, OpenAPI SDK, mocks, adapters
│   │   ├── auth/            # OAuth helpers, URL sanitizers
│   │   └── utils.ts         # Shared helpers
│   ├── providers/           # Global React providers (QueryProvider)
│   └── i18n/                # next-intl configuration
├── messages/                # Locale dictionaries (namespaced JSON)
├── docs/                    # Architecture & developer documentation
├── public/                  # Static assets
├── package.json             # Scripts, dependencies
└── vitest.config.ts         # Unit test configuration
```

---

## 4. Getting Started

### 4.1 Prerequisites

- Node.js 20.x (minimum 18.18 for Next.js 15)
- npm 10+ (or compatible package manager)
- Access to AREA backend API and logo.dev key (for live data)

### 4.2 Initial Setup

```bash
cd web
npm install
cp .env.local.example .env.local    # if present; otherwise create manually
```

Populate `.env.local` with project settings:

```bash
NEXT_PUBLIC_API_URL=http://localhost:8080/v1
API_PROXY_TARGET=http://localhost:8080/v1
CORS_ALLOWED_ORIGIN=http://localhost:8081
NEXT_PUBLIC_API_MODE=mock           # use "live" when backend is available
LOGO_DEV_API_KEY=replace-with-key   # optional; disables logo search without it
```

> `src/env.ts` validates variables at boot. If configuration is invalid, the dev server prints the error and exits.

### 4.3 Run the Application

```bash
npm run dev          # launches Next.js on http://localhost:8081
npm run lint         # type-aware linting
npm run test:unit    # vitest unit & integration suite
npm run test:e2e     # vitest e2e-like page tests
```

For production builds:

```bash
npm run build
npm run start        # serves the compiled app on port 8081
```

---

## 5. Core Concepts

- **Server vs. Client Components**: Only client components can use hooks like `useState` or `useQuery`. Server components handle redirects and initial data fetch.
- **React Query Hooks**: Generated per feature (`useServiceProvidersQuery`, `useCreateAreaMutation`) and should encapsulate request logic.
- **Internationalization**: Strings live in `messages/en.json` under namespaced keys (`DashboardPage.loading`). Wrap components in `useTranslations('Namespace')`.
- **Runtime Configuration**: `apiConfig` builds URLs respecting proxy rewrites and mock mode.
- **Authentication Flow**:
  - Login form triggers `useLoginMutation`.
  - Failed responses surface `ApiError` instances with `status`, `details`.
  - Queries with `meta.redirectOn401` redirect to `/login` during session expiry.
- **Mock Mode**: Flip to `NEXT_PUBLIC_API_MODE=mock` to load deterministic fixtures from `lib/api/mock`.

---

## 6. Adding New Features

1. **Create route or entry point**
   - Add a folder under `src/app` (server component) or update existing layout.
   - Mark as `'use client'` when interactive hooks are required.
2. **Define contracts**
   - Extend OpenAPI schemas (regenerate SDK) or create domain types in `lib/api/contracts`.
3. **Expose data hooks**
   - Add queries/mutations under `lib/api/openapi/<feature>`.
   - Export React Query hooks with typed inputs/outputs.
4. **Build UI components**
   - Use `components/ui` primitives; keep logic localized.
   - Add translations to `messages/en.json`.
5. **Write tests**
   - Unit test hooks/adapters under `lib/api/**/__tests__` or `*.test.ts`.
   - Integration tests in `e2e/` using Testing Library + `NextIntlClientProvider`.
6. **Document behavior**
   - Update docs or stories if relevant; ensure lint and typecheck pass.

---

## 7. State Management

- **React Query**
  - Default stale time: 30 seconds.
  - Global error handling in `QueryProvider` redirects on 401 when `meta.redirectOn401` is set.
  - Cache invalidation via `queryClient.invalidateQueries`.
- **Local State**
  - Prefer `useState` / `useReducer` for transient UI state (modals, forms).
  - Store derived data with `useMemo` (e.g., filtered lists).
- **Server Cache**
  - `apiFetchServer` supports `next: { revalidate, tags }` for incremental revalidation.
  - Avoid caching personalized data unless scoped via cookies.

---

## 8. Navigation

- **App Router basics**
  - Folder name = URL segment; `page.tsx` defines the route.
  - `layout.tsx` wraps child routes and can be async.
  - Grouping via `(public)` keeps marketing routes separate without affecting URL.
- **Protected Routes**
  - Use server-side guards (call `currentUserServer()` and `redirect` if unauthenticated).
  - Client components should handle 401 by redirecting back to `/login` or showing an access message.
- **Linking**
  - Prefer `next/link` inside client components.
  - Use `router.push` for imperative redirects after mutations.
- **Breadcrumbs**
  - `DynamicBreadcrumb` maps path segments to labels; update `titleMap` when adding routes.

---

## 9. API Integration

- **Access Patterns**
  - Client components use generated hooks, never call `fetch` directly.
  - Server components call `*-server.ts` helpers for SSR-safe fetching.
- **Customization**
  - Pass `clientOptions` to hooks for abort signals or custom retry behavior.
  - Mutations accept callbacks (`onSuccess`, `onError`) for side effects (e.g., toasts).
- **Error Handling**
  - Catch `ApiError` in components to surface friendly messages.
  - Use `tryRefresh: false` when you need raw 401 responses (e.g., verifying credentials).
- **Mock Data**
  - Add fixtures inside `lib/api/mock/<feature>` to mirror backend payloads.
  - Ensure adapters stay compatible between mock and live data.

---

## 10. Design System

- **Primitives**: Tailwind CSS utilities with shadcn-inspired wrappers in `components/ui`.
- **Icons**: Mix of `lucide-react` and `@tabler/icons-react`.
- **Layout Components**: Sidebar (`components/ui/sidebar`), cards, table, accordion, etc.
- **Forms**: Inputs, labels, command palette powered by Radix popovers and command.
- **Theming**: Controlled via `ThemeProvider`; use semantic Tailwind classes instead of hard-coded colors.
- **Animations**: `motion` for micro-interactions, `tw-animate-css` for ready-made transitions.

---

## 11. Best Practices

- **Type Safety**: Extend TypeScript interfaces instead of casting; align with OpenAPI definitions.
- **Translations**: Namespaces should match route or feature; avoid inline strings.
- **Access Control**: Server guards first, client redirects second.
- **Error Surfaces**: Display user-friendly messages (`toast.error`, inline feedback blocks).
- **Testing**:
  - Keep tests colocated with implementation when practical.
  - Use `NextIntlClientProvider` in JSX tests requiring translations.
- **Performance**:
  - Avoid large client bundles; keep heavy logic server-side when possible.
  - Memoize derived data; use `Suspense` and loading states for async components.
- **Code Style**:
  - Run `npm run lint` and `npm run format:fix` before commits.
  - Follow established folder names and hook naming conventions.

---

## 12. Troubleshooting

| Symptom                          | Likely Cause                                    | Resolution                                                               |
| -------------------------------- | ----------------------------------------------- | ------------------------------------------------------------------------ |
| Dev server exits with env errors | Missing `.env.local` or invalid URL             | Check console output from `src/env.ts`, fix values                       |
| Infinite redirect to login       | Backend session expired or mock mode disabled   | Verify API reachable, ensure `NEXT_PUBLIC_API_MODE=mock` for local demos |
| 401s not redirecting             | Query hook missing `meta.redirectOn401`         | Pass `meta: { redirectOn401: true }` to affected query                   |
| Tailwind styles missing          | `globals.css` not imported or build cache stale | Confirm import in `app/layout.tsx`, restart dev server                   |
| Tests cannot find translations   | Missing provider or namespace                   | Wrap component with `NextIntlClientProvider`, ensure key path exists     |

---

## Appendix

### A. Useful Commands

```bash
# Format using prettier (matches lint-staged)
npm run format:fix

# Check for outdated packages
npm outdated

# Run single Vitest file
npm run test:unit -- areas.test.tsx
```

### B. Recommended VS Code Extensions

- ESLint
- Tailwind CSS IntelliSense
- GitLens
- i18n Ally
- Vitest Explorer

### C. Contacts

- Yanis Kernoua — <yanis.kernoua@epitech.eu>

---

**Document Version**: 1.0
**Last Updated**: 1 November 2025
**Maintained By**: Web Platform Team
