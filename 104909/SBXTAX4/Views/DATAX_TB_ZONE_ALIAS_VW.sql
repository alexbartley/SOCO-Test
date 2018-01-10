CREATE OR REPLACE FORCE VIEW sbxtax4.datax_tb_zone_alias_vw (data_check_id,datax_description,reviewed_approved,verified,"PATTERN","VALUE","TYPE",primary_key,approved_date) AS
SELECT c.data_check_id, c.description datax_description, o.reviewed_Approved||' '||to_char(o.approved_date,'DD-Mon-yyyy') reviewed_Approved, o.verified||' '||to_char(o.verified_date,'DD-Mon-yyyy'),
pattern, value, type,
o.primary_key, o.approved_date
FROM datax_check_output o
JOIN datax_checks c ON (o.data_check_id = c.data_Check_id AND c.data_owner_table = 'TB_ZONE_MATCH_PATTERNS')
JOIN tb_zone_match_patterns z ON (z.zone_match_pattern_id = o.primary_key)
ORDER BY NVL(o.approved_Date,'31-DEC-9999') DESC
 
 
 
 ;