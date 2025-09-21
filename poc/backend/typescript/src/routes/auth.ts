import { Router } from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.js';
import { hashPassword, verifyPassword } from '../utils/hash.js';
import { signAccessToken, signRefreshToken } from '../utils/jwt.js';
import { isProd, config } from '../config.js';
import { randomUUID } from 'crypto';

const router = Router();

function setAuthCookies(res: Response, accessToken: string, refreshToken: string) {
  const base = {
    httpOnly: true as const,
    secure: isProd,
    sameSite: isProd ? ('none' as const) : ('lax' as const),
    path: '/',
  } as const;
  const common = config.cookieDomain ? { ...base, domain: config.cookieDomain } : base;
  res.cookie('token', accessToken, { ...common });
  res.cookie('refresh_token', refreshToken, { ...common });
}

router.post('/register', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body || {};
    if (typeof email !== 'string' || typeof password !== 'string' || password.length < 8) {
      return res.status(400).json({ error: 'Invalid email or password too short' });
    }

    const exists = await pool.query('SELECT 1 FROM users WHERE email = ?', [email.toLowerCase()]);
    if (exists.rowCount && exists.rowCount > 0) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const passwordHash = await hashPassword(password);
    const id = randomUUID();
    await pool.query('INSERT INTO users (id, email, password_hash) VALUES (?, ?, ?)', [
      id,
      email.toLowerCase(),
      passwordHash,
    ]);

    const accessToken = signAccessToken({ sub: id, email });
    const refreshToken = signRefreshToken({ sub: id, email });
    setAuthCookies(res, accessToken, refreshToken);

    return res.status(201).json({ id, email });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/auth', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body || {};
    if (typeof email !== 'string' || typeof password !== 'string') {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    const userRes = await pool.query<{ id: string; email: string; password_hash: string }>(
      'SELECT id, email, password_hash FROM users WHERE email = ?',
      [email.toLowerCase()]
    );
    if (userRes.rowCount === 0) return res.status(401).json({ error: 'Invalid credentials' });
    const user = userRes.rows[0];
    const ok = await verifyPassword(password, user.password_hash);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

    const accessToken = signAccessToken({ sub: user.id, email: user.email });
    const refreshToken = signRefreshToken({ sub: user.id, email: user.email });
    setAuthCookies(res, accessToken, refreshToken);

    return res.json({ id: user.id, email: user.email });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
