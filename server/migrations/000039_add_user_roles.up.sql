DO $$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
		CREATE TYPE "user_role" AS ENUM ('member','admin');
	END IF;
END
$$;

ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "role" "user_role" NOT NULL DEFAULT 'member';
CREATE INDEX IF NOT EXISTS "users_index_role" ON "users" ("role");
