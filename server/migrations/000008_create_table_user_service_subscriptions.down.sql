ALTER TABLE "user_service_subscriptions" DROP CONSTRAINT IF EXISTS "fk_subscriptions_identity";
ALTER TABLE "user_service_subscriptions" DROP CONSTRAINT IF EXISTS "fk_subscriptions_provider";
ALTER TABLE "user_service_subscriptions" DROP CONSTRAINT IF EXISTS "fk_subscriptions_user";
DROP INDEX IF EXISTS "subscriptions_index_status";
DROP INDEX IF EXISTS "subscriptions_index_identity_id";
DROP INDEX IF EXISTS "uq_subscription";
DROP TABLE IF EXISTS "user_service_subscriptions";
