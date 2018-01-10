CREATE OR REPLACE FORCE VIEW sbxtax4.v_pvw_tb_compliance_areas (compliance_area_id,"NAME",compliance_area_uuid,effective_zone_level_id,associated_area_count,merchant_id,start_date,end_date,change_type) AS
SELECT  compliance_area_id
            , NAME
            , compliance_area_uuid
            , effective_zone_level_id
            , associated_area_count
            , merchant_id
            , start_date
            , end_date
            , change_type
    FROM    pvw_tb_compliance_areas
 
 ;