CREATE OR REPLACE FORCE VIEW content_repo.vresearch_source_tags ("ID",research_source_id,tag_id,tag_name,tag_type_id,status) AS
select rst.id, research_source_id, t.id tag_id, t.name tag_name, t.tag_type_id, rst.status
from research_source_tags rst
join tags t on (t.id = rst.tag_id)
 
 
 ;