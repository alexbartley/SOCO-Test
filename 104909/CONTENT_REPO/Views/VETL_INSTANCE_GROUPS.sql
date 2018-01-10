CREATE OR REPLACE FORCE VIEW content_repo.vetl_instance_groups (instance_group_id,tdr_etl_instance_id,instance_name,tdr_etl_tag_group_id,tag_group_name,gis_flag,schema_name,sort_order) AS
select a.id instance_group_id, b.id tdr_etl_instance_id, b.instance_name, c.id tdr_etl_tag_group_id, c.tag_group_name, a.gis_flag, b.schema_name, c.sort_order
from tdr_etl_instance_groups a join tdr_etl_instances b on a.tdr_etl_instance_id = b.id
  join tdr_etl_tag_groups c on c.id = a.tdr_etl_tag_group_id
order by sort_order;