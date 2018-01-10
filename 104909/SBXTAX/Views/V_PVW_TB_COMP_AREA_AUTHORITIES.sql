CREATE OR REPLACE FORCE VIEW sbxtax.v_pvw_tb_comp_area_authorities (compliance_area_auth_id,compliance_area_id,"NAME",compliance_area_uuid,authority_id,authority_name,change_type) AS
SELECT  p.compliance_area_auth_id
            , p.compliance_area_id
            , COALESCE(tca.NAME, pca.NAME, pca2.NAME) NAME
            , COALESCE(tca.compliance_area_uuid, pca.compliance_area_uuid, pca2.compliance_area_uuid) compliance_area_uuid
            , p.authority_id
            , p.authority_name
            , p.change_type
    FROM    pvw_tb_comp_area_authorities p
            LEFT JOIN tb_compliance_areas tca ON (p.compliance_area_id = tca.compliance_area_id)
            LEFT JOIN pvw_tb_compliance_areas pca ON (p.compliance_area_id = pca.compliance_area_id)
            LEFT JOIN pvw_tb_compliance_areas pca2 ON (p.compliance_area_auth_id = pca2.compliance_area_uuid)   -- 01/08/16
 ;