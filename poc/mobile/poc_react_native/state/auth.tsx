import React, { createContext, useContext, useState } from "react";
import { login as apiLogin, register as apiRegister } from "@/lib/api";
import type { Tokens, User } from "@/lib/types";

type Ctx = {
  user: User | null;
  tokens: Tokens;
  register: (email: string, password: string) => Promise<void>;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
};

const AuthCtx = createContext<Ctx | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [tokens, setTokens] = useState<Tokens>({ access_token: null, refresh_token: null });

  async function register(email: string, password: string) {
    await apiRegister(email, password);
  }

  async function login(email: string, password: string) {
    const res = await apiLogin(email, password);
    setTokens({ access_token: res.access_token, refresh_token: res.refresh_token });
    setUser({ email });
  }

  function logout() {
    setTokens({ access_token: null, refresh_token: null });
    setUser(null);
  }

  return (
    <AuthCtx.Provider value={{ user, tokens, register, login, logout }}>
      {children}
    </AuthCtx.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthCtx);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
