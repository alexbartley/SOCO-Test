CREATE OR REPLACE FORCE VIEW sbxtax3.datax_tb_authorities_vw (data_check_id,reviewed_approved,verified,removed,record_key,authority_name,uuid,region_code,invoice_description,authority_category,location_code,official_name,simple_registration_mask,registration_mask,erp_tax_code,effective_zone_level,admin_zone_level,primary_key) AS
SELECT c.data_check_id, o.reviewed_Approved||' '||to_char(o.approved_date,'DD-Mon-yyyy') reviewed_Approved, o.verified||' '||to_char(o.verified_date,'DD-Mon-yyyy'), o.removed, 'Name='||a.name||'| Uuid='||uuid record_key, a.name authority_name, a.uuid, a.region_code, a.invoice_Description, a.authority_Category,
a.location_code, a.official_name, a.simple_registration_mask, a.registration_mask, a.erp_tax_code, el.name effective_zone_level, al.name admin_zone_level,
o.primary_key
FROM tb_authorities a, tb_zone_levels el, tb_zone_levels al, datax_check_output o, datax_checks c
WHERE a.authority_id = o.primary_key
AND c.data_Check_id = o.data_check_id
AND c.data_owner_table = 'TB_AUTHORITIES'
AND el.zone_level_id = a.effective_zone_level_id
AND al.zone_level_id = a.admin_zone_level_id
 
 ;