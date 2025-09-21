import { migrateUp, pool } from './db.js';
import { startServer } from './server.js';

async function main() {
  await migrateUp();
  startServer();
}

main().catch(async (e) => {
  console.error(e);
  await pool.end().catch(() => {});
  process.exit(1);
});

