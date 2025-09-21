import Database from 'better-sqlite3';
import { config } from './config.js';
import { readdirSync, readFileSync, mkdirSync } from 'fs';
import path from 'path';

type QueryResult<T> = { rows: T[]; rowCount: number };

const dbDir = path.dirname(config.databaseFile);
mkdirSync(dbDir, { recursive: true });

const database = new Database(config.databaseFile);
database.pragma('journal_mode = WAL');
database.pragma('foreign_keys = ON');
let isClosed = false;

function isSelectStatement(sql: string): boolean {
  const firstToken = sql.trim().split(/\s+/)[0]?.toLowerCase() ?? '';
  return ['select', 'with', 'pragma', 'explain'].includes(firstToken);
}

export const pool = {
  async query<T = unknown>(sql: string, params: unknown[] = []): Promise<QueryResult<T>> {
    const stmt = database.prepare(sql);
    if (isSelectStatement(sql) || /\breturning\b/i.test(sql)) {
      const rows = stmt.all(...params) as T[];
      return { rows, rowCount: rows.length };
    }
    const info = stmt.run(...params);
    return { rows: [] as T[], rowCount: info.changes ?? 0 };
  },
  async close(): Promise<void> {
    if (isClosed) return;
    database.close();
    isClosed = true;
  },
  async end(): Promise<void> {
    await pool.close();
  },
};

type Migration = { name: string; sql: string };

function ensureMigrationsTable() {
  database.exec(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      applied_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);
}

function loadMigrations(): Migration[] {
  const dir = path.resolve('src', 'migrations');
  let files: string[] = [];
  try {
    files = readdirSync(dir)
      .filter((f) => f.endsWith('.sql'))
      .sort();
  } catch (e) {
    return [];
  }
  return files.map((f) => ({ name: f, sql: readFileSync(path.join(dir, f), 'utf8') }));
}

export async function migrateUp() {
  ensureMigrationsTable();
  const migrations = loadMigrations();
  const appliedRows = database.prepare('SELECT name FROM schema_migrations').all() as { name: string }[];
  const applied = new Set(appliedRows.map((row) => row.name));

  const runMigration = database.transaction((migration: Migration) => {
    database.exec(migration.sql);
    database.prepare('INSERT INTO schema_migrations(name) VALUES (?)').run(migration.name);
  });

  for (const migration of migrations) {
    if (applied.has(migration.name)) continue;
    try {
      runMigration(migration);
      console.log(`Applied migration: ${migration.name}`);
    } catch (err) {
      console.error(`Migration failed: ${migration.name}`);
      throw err;
    }
  }
}

async function main() {
  const cmd = process.argv[2];
  if (cmd === 'migrate') {
    await migrateUp();
    await pool.close();
    console.log('Migrations complete');
    return;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
