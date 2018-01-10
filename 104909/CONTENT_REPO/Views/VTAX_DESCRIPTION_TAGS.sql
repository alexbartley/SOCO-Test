CREATE OR REPLACE FORCE VIEW content_repo.vtax_description_tags ("ID",tax_desc_id,tag_id,"TAG",entered_by,entered_date) AS
SELECT ptt.id, td.id, pt.id, pt.name, ptt.entered_by, ptt.entered_date
FROM package_tag_table_mapping ptt
JOIN tags pt on (pt.id = ptt.package_tag_id)
JOIN tax_descriptions td ON (td.id = ptt.primary_key)
WHERE ptt.table_name = 'TAX_DESCRIPTIONS'
 
 
 ;