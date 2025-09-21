import type { AuthResponse } from "@/lib/types";

export const BASE_URL = "http://10.0.2.2:8080";

async function post<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify(body),
  });
  const data = (await res.json().catch(() => ({}))) as any;
  if (!res.ok) throw new Error(String(data?.error || data?.message || `HTTP ${res.status}`));
  return data as T;
}

export function register(email: string, password: string) {
  return post<{ id: number; email: string }>("/register", { email, password });
}

export function login(email: string, password: string): Promise<AuthResponse> {
  return post<AuthResponse>("/auth", { email, password });
}
