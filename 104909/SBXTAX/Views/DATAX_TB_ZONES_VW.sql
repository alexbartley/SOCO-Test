CREATE OR REPLACE FORCE VIEW sbxtax.datax_tb_zones_vw (data_check_id,reviewed_approved,verified,record_key,zone_1_name,zone_2_name,zone_2_level,zone_3_name,zone_3_level,zone_4_name,zone_4_level,zone_5_name,zone_5_level,zone_6_name,zone_6_level,zone_7_name,zone_7_level,is_bottom_up,terminates_processing,default_flag,code_2char,code_3char,code_iso,code_fips,primary_key,approved_date) AS
SELECT c.data_check_id, o.reviewed_Approved||' '||to_char(o.approved_date,'DD-Mon-yyyy') reviewed_Approved, o.verified||' '||to_char(o.verified_date,'DD-Mon-yyyy'), 'ZoneHierarchy='||z.zone_1_name||'| '||z.zone_2_name||'| '||NVL(z.zone_3_name,'')||'| '||NVL(z.zone_4_name,'')||'| '||NVL(z.zone_5_name,'')||'| '||NVL(z.zone_6_name,'')||'| '||NVL(z.zone_7_name,''),
z.zone_1_name,
z.zone_2_name, zl2.name zone_2_level,
z.zone_3_name, zl3.name zone_3_level,
z.zone_4_name, zl4.name zone_4_level,
z.zone_5_name, zl5.name zone_5_level,
z.zone_6_name, zl6.name zone_6_level,
z.zone_7_name, zl7.name zone_7_level,
NVL(z.reverse_flag,'N') Is_Bottom_Up,
NVL(z.terminator_flag,'N') Terminates_processing,
DEFAULT_FLAG, CODE_2char, code_3char, code_iso, code_fips,
o.primary_key, approved_date
FROM datax_check_output o
JOIN datax_checks c ON (o.data_check_id = c.data_Check_id AND c.data_owner_table = 'TB_ZONES')
JOIN ct_zone_Tree z ON (z.primary_key = o.primary_key)
JOIN tb_zone_levels zl2 ON (zl2.zone_level_id = z.zone_2_level_id)
JOIN tb_zone_levels zl3 ON (zl3.zone_level_id = z.zone_3_level_id)
LEFT OUTER JOIN tb_zone_levels zl4 ON (zl4.zone_level_id = NVL(z.zone_4_level_id,-1000))
LEFT OUTER JOIN tb_zone_levels zl5 ON (zl5.zone_level_id = NVL(z.zone_5_level_id,-1000))
LEFT OUTER JOIN tb_zone_levels zl6 ON (zl6.zone_level_id = NVL(z.zone_6_level_id,-1000))
LEFT OUTER JOIN tb_zone_levels zl7 ON (zl7.zone_level_id = NVL(z.zone_7_level_id,-1000))
ORDER BY NVL(o.approved_Date,'31-DEC-9999') DESC
 
 
 ;