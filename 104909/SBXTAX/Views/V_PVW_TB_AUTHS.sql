CREATE OR REPLACE FORCE VIEW sbxtax.v_pvw_tb_auths (jurisdiction_nkid,uuid,"NAME",location_code,official_name,description,authority_category,authority_type,admin_zone_level,effective_zone_level,default_prod_group,registration_mask) AS
select a.jurisdiction_nkid, a.uuid, a.name, location_Code, official_name, a.description, authority_category, aty.name, al.name, el.name, pg.name default_prod_group, a.registration_mask
from pvw_tb_authorities a
left outer join tb_authority_types aty on (aty.authority_type_id = a.authority_type_id)
left outer join tb_zone_levels al on (al.zone_level_id = a.admin_zone_level_id)
left outer join tb_zone_levels el on (el.zone_level_id = a.effective_zone_level_id)
left outer join tb_product_groups pg on (pg.product_Group_id = a.product_group_id)
 
 ;