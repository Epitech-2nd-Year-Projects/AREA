**TypeScript Backend Summary**

**Highlights**
- Rapid iteration with Express 5, `ts-node` + `nodemon` hot‑reload.
- Straightforward JSON handling and middleware; cookies via `cookie-parser`.
- Simple auth primitives: `bcryptjs` hashing and JWT issuance (`jsonwebtoken`).
- Typed config/env loading (`dotenv`, strict TS) catches issues early.
- Embedded SQLite via `better-sqlite3`; zero external service required and migrations stay lightweight.

**Challenges**
- ESM + `ts-node` + `NodeNext` requires `.js` import suffixes and loader flags; easy to misconfigure.
- Type definitions around Express 5 and middleware can drift and cause minor friction.
- Cross‑origin auth is subtle: `sameSite`, `secure`, and cookie domain must be tuned per environment.
- DIY SQL and migrations mean more manual work (no ORM helpers, fewer compile‑time guarantees).
- SQLite is single-process; long-running writes block other queries, so keep transactions short.

**Runtime**
- Fast startup and good throughput for simple routes and local SQLite I/O.
- Password hashing is CPU‑bound; tuning bcrypt rounds affects latency under load.
- Memory footprint is higher than Rust/Go but acceptable; GC impact negligible at low traffic.

**Dev Speed**
- Fast: scaffolding routes, health check, auth endpoints, JWT/cookie wiring.
- Slower: initial ESM/tooling setup (`ts-node` loader, `NodeNext` resolution) and migration harness.
- Schema evolution/validation slower without an ORM; more hand‑rolled SQL and checks.
- Excellent DX from TypeScript types and editor tooling; hot‑reload offsets build overhead.

**Dev Notes**
- Scripts: `npm run dev`, `npm run build`, `npm start`, `npm run migrate`.
- Requires `.env` (`JWT_SECRET`; optional `DATABASE_FILE`, cookie domain, and token expirations). Default DB lives at `./data/database.sqlite` and is created automatically.
- Uses `module`/`moduleResolution: NodeNext`; imports include `.js` suffix to match ESM output.
- Consider adding CORS middleware, request validation (e.g., zod), and basic tests.

**Bottom Line**
- TypeScript + Express provides high productivity and a rich ecosystem. Great fit for rapid development and moderate workloads; expect some setup friction (ESM, cross‑origin cookies) and slightly higher runtime overhead compared to systems languages.
