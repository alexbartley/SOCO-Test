CREATE OR REPLACE FORCE VIEW sbxtax2.datax_tb_zone_auth_vw (data_check_id,reviewed_approved,verified,datax_description,record_key,zone_1_name,zone_2_name,zone_2_level,zone_3_name,zone_3_level,zone_4_name,zone_4_level,zone_5_name,zone_5_level,zone_6_name,zone_6_level,zone_7_name,zone_7_level,authority_name,primary_key) AS
SELECT /*+ index(z ct_zone_auth_pk) */ c.data_check_id, o.reviewed_Approved||' '||to_char(o.approved_date,'DD-Mon-yyyy') reviewed_Approved, o.verified||' '||to_char(o.verified_date,'DD-Mon-yyyy'), c.description datax_description,
'AuthorityName='||z.authority_name||'| ZoneHierarchy='||z.zone_1_name||'| '||z.zone_2_name||'| '||NVL(z.zone_3_name,'')||'| '||NVL(z.zone_4_name,'')||'| '||NVL(z.zone_5_name,'')||'| '||NVL(z.zone_6_name,'')||'| '||NVL(z.zone_7_name,'') record_key,
z.zone_1_name,
z.zone_2_name, zl2.name zone_2_level,
z.zone_3_name, zl3.name zone_3_level,
z.zone_4_name, zl4.name zone_4_level,
z.zone_5_name, zl5.name zone_5_level,
z.zone_6_name, zl6.name zone_6_level,
z.zone_7_name, zl7.name zone_7_level,
z.authority_name,
o.primary_key
FROM datax_check_output o
JOIN ct_zone_authorities z ON (z.zone_authority_id = o.primary_key)
JOIN datax_checks c ON (o.data_check_id = c.data_Check_id AND c.data_owner_table = 'TB_ZONE_AUTHORITIES')
JOIN tb_zone_levels zl2 ON (zl2.zone_level_id = z.zone_2_level_id)
LEFT OUTER JOIN tb_zone_levels zl3 ON (zl3.zone_level_id = z.zone_3_level_id)
LEFT OUTER JOIN tb_zone_levels zl4 ON (zl4.zone_level_id = NVL(z.zone_4_level_id,-1000))
LEFT OUTER JOIN tb_zone_levels zl5 ON (zl5.zone_level_id = NVL(z.zone_5_level_id,-1000))
LEFT OUTER JOIN tb_zone_levels zl6 ON (zl6.zone_level_id = NVL(z.zone_6_level_id,-1000))
LEFT OUTER JOIN tb_zone_levels zl7 ON (zl7.zone_level_id = NVL(z.zone_7_level_id,-1000))
ORDER BY NVL(o.reviewed_approved,'0')
 
 ;