export type AuthResponse = { access_token: string; refresh_token: string };
export type Tokens = { access_token: string | null; refresh_token: string | null };
export type User = { email: string };
export type RootStackParamList = { Login: undefined; Register: undefined; Home: undefined };
