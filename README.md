# Monorepo Stack

This repository contains three projects developed and deployed together using `docker-compose`:

```
.
├── server/         # Golang backend
│   ├── cmd/server/ # Entrypoint
│   └── internal/   # Business logic, handlers, middleware
├── web/            # Next.js frontend
│   └── public/     # Serves the built client.apk
├── mobile/         # Flutter app (Android APK build)
└── docker-compose.yml
```

- **server** exposes `:8080/about.json`.
- **client_web** exposes `:8081/client.apk` and the Next.js app.
- **client_mobile** builds the Flutter APK and writes it into a shared volume.

---

## Clone

```bash
git clone git@github.com:Epitech-2nd-Year-Projects/AREA.git
cd AREA
```

---

## Node, Go, Flutter toolchains

Make sure you have:

- Go ≥ 1.25.1
- Node.js ≥ 20 with npm
- Flutter stable channel

---

## Husky

Husky enforces formatting, linting, and type checks before each commit.

### One-time setup

```bash
npm install
npx husky init
```

### Pre-commit behavior

- Runs Prettier on staged files.
- Runs ESLint with `--fix` on staged TS/JS.
- Runs `tsc --noEmit` if TS files are staged.

If any step fails, the commit is blocked until fixed.

---

## Build and run with Docker Compose

```bash
docker compose build
docker compose up
```

Verify:

```bash
curl http://localhost:8080/about.json
curl -I http://localhost:8081/client.apk
```

---

## CI/CD

GitHub Actions runs:

- Lint and tests for Go, Next.js, and Flutter.
- Builds Docker images and APK.
- Verifies endpoints with `docker compose up`.

---

## Local development

- **Go server**: `cd server && go run ./cmd/server`
- **Web**: `cd web && npm run dev`
- **Mobile**: `cd mobile && flutter run`
