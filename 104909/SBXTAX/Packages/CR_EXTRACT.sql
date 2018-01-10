CREATE OR REPLACE PACKAGE sbxtax.cr_extract
IS

/*

Date            Author            Comments
----------------------------------------------------------------------------------------------------------
11/01/2017      PMR               All GIS references have been removed from regular ETL processing,
                                  moved to GIS_ETL.


*/

    function prod_level_token RETURN NUMBER;
    procedure authority_data(package_i IN VARCHAR2);
    PROCEDURE rate_data;
    --PROCEDURE rule_data;
    procedure rule_data_2;
    PROCEDURE product_data;
    PROCEDURE reference_data;
    PROCEDURE product_taxability_data_2;
    PROCEDURE remove_local_extract(entity_i IN VARCHAR2, etl_id_i IN NUMBER);
    PROCEDURE empty_tmp;
    PROCEDURE local_extract(package_i IN VARCHAR2, entity_i IN VARCHAR2);
    PROCEDURE queue_records(package_i IN VARCHAR2);
    --PROCEDURE unextract_by_jurisdiction(name_i IN VARCHAR2);
    PROCEDURE unextract_jurisdictions;
    PROCEDURE unextract_commodities;
    PROCEDURE unextract_ref_groups;
    PROCEDURE unextract_record(entity_i IN VARCHAR2, nkid_i IN NUMBER, rid_i IN NUMBER);
    --PROCEDURE insert_rule_changes(jta_nkid_i IN NUMBER, rid_i IN NUMBER, p_rid_i IN NUMBER);
    --procedure compare_curr_to_last;
    PROCEDURE get_product_exceptions;

    /*
    -- GIS D2C Procedures -- CRAPP-1859
    PROCEDURE compliance_area_data;
    PROCEDURE compliance_area_auth_data(make_changes_i IN NUMBER); -- 01/26/16 crapp-2244 added parameter
    */
    -- Changes for CRAPP-3953
    PROCEDURE set_extracted_date (entity_name_i VARCHAR2);
END;
/