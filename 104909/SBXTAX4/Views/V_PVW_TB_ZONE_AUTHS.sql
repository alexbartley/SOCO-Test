CREATE OR REPLACE FORCE VIEW sbxtax4.v_pvw_tb_zone_auths (state_code,zone_id,authority_id,authority_name,zone_3_name,zone_4_name,zone_5_name,zone_6_name,zone_7_name,tree_type) AS
SELECT  DISTINCT 
        p.state_code
        , p.zone_id
        , p.authority_id
        , p.authority_name
        , COALESCE(c.zone_3_name, t.zone_3_name, z.state)    zone_3_name
        , COALESCE(c.zone_4_name, t.zone_4_name, z.county)   zone_4_name
        , COALESCE(c.zone_5_name, t.zone_5_name, z.city)     zone_5_name
        , COALESCE(c.zone_6_name, t.zone_6_name, z.postcode) zone_6_name
        , COALESCE(c.zone_7_name, t.zone_7_name, z.plus4)    zone_7_name
        , CASE WHEN p.zone_id < -1 THEN 'Detach' ELSE 'Attach' END tree_type
FROM   pvw_tb_zone_authorities p

       LEFT JOIN ct_zone_authorities c ON c.primary_key = CASE WHEN p.zone_id < -1 THEN (p.zone_id * -1)
                                                               ELSE p.zone_id
                                                          END

       LEFT JOIN tdr_etl_ct_zone_authorities t ON t.primary_key = CASE WHEN p.zone_id < -1 THEN (p.zone_id * -1)
                                                                   ELSE p.zone_id
                                                              END

       LEFT JOIN (SELECT DISTINCT zc.*, za.*
                  FROM   tdr_etl_us_zone_changes zc
                         JOIN tdr_etl_zone_attributes za on (za.tmp_id = zc.id)
                  WHERE  change_type = 'Add'
                 ) z ON  z.id = CASE WHEN p.zone_id-TRUNC(p.zone_id) = 0.1 THEN TRUNC(p.zone_id)
                                     ELSE NULL 
                                END 
ORDER BY 7,8,5,6;