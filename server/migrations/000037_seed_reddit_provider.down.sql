DELETE FROM "service_components"
WHERE "name" IN ('reddit_new_post', 'reddit_comment_post')
  AND "version" = 1;

DELETE FROM "service_providers"
WHERE "name" = 'reddit';
