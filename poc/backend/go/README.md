**Go Backend Summary**

**Highlights**
- Simple, fast HTTP with `net/http` + `ServeMux` (no heavy framework).
- Clear auth primitives: bcrypt password hashing and JWT pair issuance.
- Minimal MongoDB setup: single unique index on `users.email` via a tiny migrator.
- Straightforward config via `.env` (`PORT`, `MONGO_URI`, `MONGO_DB`, `JWT_SECRET`, …).

**Challenges**
- MongoDB driver ergonomics: `context.Context` everywhere, `ObjectID` conversions, and BSON vs JSON tags.
- CORS and cookie flags (SameSite/Domain/Secure) are easy to misconfigure for cross‑origin auth.
- Error surfaces from the Mongo driver (duplicate key, index exists) require explicit handling.

**Runtime**
- Go server starts quickly and remains memory‑light; handler latency is low.
- MongoDB connection pooling behaves well; cold connect + initial ping adds a small startup cost.
- Bcrypt dominates auth CPU time at higher cost factors; tune for your SLOs.

**Dev Notes**
- Endpoints: `POST /register`, `POST /auth`, `POST /refresh`, `POST /logout`, `GET /healthz`.
- Cookies carry access/refresh tokens; adjust `COOKIE_DOMAIN`, `COOKIE_SECURE`, and `COOKIE_SAMESITE` per environment.
- Indexing matters: the unique index on `users.email` is essential for correctness and performance.
- Data model is intentionally lean and schema‑less; validations live in handlers.

**What Felt Fast**
- Wiring routes and JSON with the standard library.
- Auth token generation/verification with `golang-jwt/jwt`.
- Creating the minimal Mongo "migration" to ensure indexes.

**What Took Longer**
- Getting cookie/CORS settings right for cross‑origin credentials.
- Handling Mongo specifics: `primitive.ObjectID`, duplicate key errors, and typed decode structs.
- Deciding how much schema/validation to push to code in a schema‑less setup.

**Bottom Line**
- Go + MongoDB makes for a compact, fast baseline service. Development is quick once Mongo driver patterns and cookie/CORS nuances are set. For larger domains, consider adding structured validation and observability; for higher security/throughput, tune bcrypt cost and ensure proper indexing.
