import jwt, { type Secret } from 'jsonwebtoken';
import { config } from '../config.js';

export type JwtPayload = {
  sub: string;
  email: string;
};

export function signAccessToken(payload: JwtPayload): string {
  return jwt.sign(payload, config.jwtSecret as Secret, { expiresIn: config.jwtExpiresIn });
}

export function signRefreshToken(payload: JwtPayload): string {
  return jwt.sign({ ...payload, typ: 'refresh' }, config.jwtSecret as Secret, { expiresIn: config.refreshExpiresIn });
}

export function verifyToken<T extends object = any>(token: string): T {
  return jwt.verify(token, config.jwtSecret as Secret) as T;
}
