CREATE OR REPLACE FORCE VIEW sbxtax4.v_pvw_tb_zones (zone_id,"NAME",parent_zone_id,parent_name,code_fips,zone_3_name,zone_4_name,zone_5_name,zone_6_name,zone_7_name,reverse_flag,terminator_flag,default_flag,tree_type) AS
SELECT  DISTINCT
        p.zone_id
        ,p.NAME
        ,p.parent_zone_id
        ,COALESCE(tt.zone_6_name, tt.zone_5_name, tt.zone_4_name, tt.zone_3_name) parent_name
        ,p.code_fips
        ,CASE WHEN NAME = '.' THEN z.zone_3_name ELSE tt.zone_3_name END zone_3_name
        ,CASE WHEN NAME = '.' THEN z.zone_4_name ELSE tt.zone_4_name END zone_4_name
        ,CASE WHEN NAME = '.' THEN z.zone_5_name ELSE tt.zone_5_name END zone_5_name
        ,CASE WHEN NAME = '.' THEN z.zone_6_name ELSE tt.zone_6_name END zone_6_name
        ,CASE WHEN NAME = '.' THEN z.zone_7_name ELSE tt.zone_7_name END zone_7_name
        ,CASE WHEN NAME = '.' THEN z.reverse_flag ELSE tt.reverse_flag END reverse_flag
        ,CASE WHEN NAME = '.' THEN z.terminator_flag ELSE tt.terminator_flag END terminator_flag
        ,CASE WHEN NAME = '.' THEN z.default_flag ELSE tt.default_flag END default_flag
        ,CASE WHEN NAME = '.' THEN 'Delete'
              WHEN p.zone_id-TRUNC(p.zone_id) = 0.1 THEN 'Add'
              ELSE 'Update' END tree_type
FROM pvw_tb_zones p
     LEFT JOIN ct_zone_tree z ON z.primary_key = p.zone_id
     LEFT JOIN tdr_etl_ct_zone_tree tt ON p.code_fips = tt.code_fips;