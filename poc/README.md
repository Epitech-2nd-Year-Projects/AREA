# 📘 Benchmark: Final choice

## 🖥️ Frontend – Next.js

**Why chosen**

* Balanced SSR, client rendering, and caching strategies.
* Scales well for authenticated flows and dashboards.
* Built-in performance helpers (image/font optimization, code-splitting).
* Strong ecosystem with TypeScript and TanStack Query.
* Team had prior experience with React/Next.js, reducing onboarding cost.

**Benchmark note**: Alternatives like Angular and Nuxt were evaluated. Angular offers structure but adds boilerplate. Nuxt provides fast iteration but weaker cache/auth handling compared to Next.js.

---

## ⚙️ Backend – Golang

**Why chosen**

* Fast, lightweight HTTP server with low latency.
* Simple authentication primitives (bcrypt, JWT).
* Easy deployment footprint, memory-efficient.
* Team had prior experience with Go, ensuring faster delivery.

**Benchmark note**: Rust and TypeScript were considered. Rust is safer but has a steep async/borrowing curve. TypeScript is productive but higher runtime overhead. Go provided the most practical speed-to-delivery balance.

---

## 🗄️ Database – PostgreSQL

**Why chosen**

* Reliable relational database with robust ACID transactions.
* Ideal for complex domain logic and structured queries.
* Strong ecosystem and tooling for schema migrations and indexing.
* Team had prior PostgreSQL experience, reducing operational risk.

**Benchmark note**: Other trials used MongoDB, which is flexible but requires more manual schema control. PostgreSQL’s robustness fit long-term complexity better.

---

## 📱 Mobile – Flutter

**Why chosen**

* Single codebase for Android and iOS.
* Very fast development with hot reload.
* Rich widget ecosystem for smooth UX.
* Efficient for scaling across platforms without duplicated work.

**Benchmark note**: Kotlin native offers best Android performance but doubles effort for iOS. React Native is strong but heavier with native bridging. Flutter struck the best productivity/portability balance.

---

## ✅ Final Stack justification

* **Next.js**: Best balance of SSR, auth, caching, and performance, with team experience.
* **Golang**: Fast HTTP, clear auth, simplicity, and team familiarity.
* **PostgreSQL**: Reliable, relational, strong transactions, with prior team expertise.
* **Flutter**: Fast cross-platform with smooth UX, efficient for mobile delivery.

This combination gives scalability, reliability, and speed of development while leveraging existing team strengths.
