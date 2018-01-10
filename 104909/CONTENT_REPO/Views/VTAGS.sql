CREATE OR REPLACE FORCE VIEW content_repo.vtags ("ID",tag_type_id,tag_name,table_name,entity_alias,contains_entities,entered_by,entered_date) AS
SELECT DISTINCT t.id, t.tag_type_id, t.name, NVL(table_name,'NONE'),
    NVL(table_name,'NONE')  entity_alias,
    CASE WHEN ttm.id IS NOT NULL THEN 1 ELSE 0 END contains_entities, t.entered_by, t.entered_date
FROM tags t
LEFT OUTER JOIN package_tag_table_mapping ttm ON (t.id = ttm.package_tag_id)
 
 
 ;