**Nuxt Frontend Summary**

**Highlights**
- File‑based routing made pages quick to scaffold.
- `script setup` + Composition API felt concise and type‑friendly.
- `useFetch` with `runtimeConfig.public.apiBase` simplified API calls.
- Cookie auth worked via `credentials: 'include'` without extra wiring.
- Tailwind via `@nuxtjs/tailwindcss` enabled fast, consistent UI work.

**Challenges**
- Cross‑origin cookies: aligning CORS and `credentials` was easy to miss.
- SSR vs CSR: knowing when `useFetch` runs server‑side required attention.
- Runtime config: mapping `API_BASE` env to `public.apiBase` is nuanced.
- Error typing from `useFetch` needs narrowing for good UX messages.
- Subtle defaults (e.g., fetch baseURL, headers) can hide mistakes.

**Runtime**
- Dev server is snappy; HMR is effectively instant for Vue/Tailwind.
- Minimal client code for the auth forms keeps loads responsive.
- No global state means small surface; scaling would need composables.

**Dev Notes**
- Configure backend URL with `API_BASE` env or edit `nuxt.config.ts`.
- Use `credentials: 'include'` for cookie‑based auth; match CORS server‑side.
- Tailwind utilities cover layout/states; no component lib used here.
- Pages live in `app/pages` with simple navigation via `NuxtLink`.
- Consider an `auth` composable + route guards for protected areas.

**Bottom Line**
- Nuxt made the PoC fast to build: routing, data‑fetching, and styling came together quickly. The main friction was around SSR semantics and cross‑origin cookie setup; once those were clarified, iteration speed and developer experience were excellent.

