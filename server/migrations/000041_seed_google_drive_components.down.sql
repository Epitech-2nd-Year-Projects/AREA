-- Remove Google Drive components
DELETE FROM "service_components" 
WHERE "name" IN ('gdrive_new_file_in_folder', 'gdrive_file_with_name_created', 'gdrive_move_file')
AND provider_id IN (SELECT id FROM "service_providers" WHERE name = 'google');