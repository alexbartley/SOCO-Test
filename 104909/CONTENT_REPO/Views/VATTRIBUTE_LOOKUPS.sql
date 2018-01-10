CREATE OR REPLACE FORCE VIEW content_repo.vattribute_lookups (lookup_value,attribute_name,attribute_category,entered_by,entered_date) AS
SELECT al.value lookup_value, aa.name attribute_name, ac.name attribute_category, al.entered_by, al.entered_date
FROM additional_attributes aa
JOIN attribute_categories ac ON (ac.id = aa.attribute_category_id)
JOIN attribute_lookups al ON (al.attribute_id = aa.id)
-- no change just a recompile 5/19/14
 
 
 ;