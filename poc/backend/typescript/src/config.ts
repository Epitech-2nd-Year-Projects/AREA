import dotenv from 'dotenv';
import type { StringValue } from 'ms';
import path from 'path';

dotenv.config();

function required(name: string, value: string | undefined): string {
  if (!value) throw new Error(`Missing env var: ${name}`);
  return value;
}

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  databaseFile: path.resolve(process.env.DATABASE_FILE || 'data/database.sqlite'),
  jwtSecret: required('JWT_SECRET', process.env.JWT_SECRET),
  jwtExpiresIn: (process.env.JWT_EXPIRES_IN || '15m') as StringValue,
  refreshExpiresIn: (process.env.REFRESH_TOKEN_EXPIRES_IN || '7d') as StringValue,
  cookieDomain: process.env.COOKIE_DOMAIN || '',
  nodeEnv: process.env.NODE_ENV || 'development',
};

export const isProd = config.nodeEnv === 'production';
