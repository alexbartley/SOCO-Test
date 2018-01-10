CREATE OR REPLACE FORCE VIEW content_repo.veffective_levels (location_category_id,location_category,hierarchy_level,entered_by,entered_date) AS
select distinct lc.id, lc.name, h_level, lc.entered_by, lc.entered_date
from hierarchy_definitions hd
join hierarchy_levels lh on (hd.id = lh.hierarchy_definition_id)
join geo_area_Categories lc on (lc.id = lh.geo_area_category_id)
where hd.name in ('US State to District Hierarchy','International Non-Standard Hierarchy')
 
 
 ;