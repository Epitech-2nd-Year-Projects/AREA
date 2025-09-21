import express from 'express';
import cookieParser from 'cookie-parser';
import { config } from './config.js';
import authRouter from './routes/auth.js';

export function createServer() {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json());
  app.use(cookieParser());

  app.get('/health', (_req, res) => res.json({ ok: true }));
  app.use('/', authRouter);

  app.use((_req, res) => res.status(404).json({ error: 'Not found' }));

  app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  });

  return app;
}

export function startServer() {
  const app = createServer();
  app.listen(config.port, () => {
    console.log(`API listening on http://localhost:${config.port}`);
  });
}

