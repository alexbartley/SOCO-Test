CREATE OR REPLACE PROCEDURE sbxtax3.datax_any_98
   (runId IN OUT NUMBER)
   IS
   --<data_check id="98" name="Check for Invalid Dates" >
   dataCheckId NUMBER := -639;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_ANY_98 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT authority_logic_group_xref_id, 'TB_AUTHORITY_LOGIC_GROUP_XREF', dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_LOGIC_GROUP_XREF
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT material_Set_list_id, 'TB_MATERIAL_SET_LISTS', dataCheckId, runId, SYSDATE
    FROM TB_MATERIAL_SET_LISTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT rate_id, 'TB_RATES', dataCheckId, runId, SYSDATE
    FROM TB_RATES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT authority_logic_element_id, 'TB_AUTHORITY_LOGIC_ELEMENTS', dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_LOGIC_ELEMENTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT date_determination_rule_id, 'TB_DATE_DETERMINATION_RULES', dataCheckId, runId, SYSDATE
    FROM TB_DATE_DETERMINATION_RULES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT contributing_authority_id, 'TB_CONTRIBUTING_AUTHORITIES', dataCheckId, runId, SYSDATE
    FROM TB_CONTRIBUTING_AUTHORITIES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT rule_output_id, 'TB_RULE_OUTPUTS', dataCheckId, runId, SYSDATE
    FROM TB_RULE_OUTPUTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT material_set_list_product_id, 'TB_MATERIAL_SET_LIST_PRODUCTS', dataCheckId, runId, SYSDATE
    FROM TB_MATERIAL_SET_LIST_PRODUCTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT reference_value_id, 'TB_REFERENCE_VALUES', dataCheckId, runId, SYSDATE
    FROM TB_REFERENCE_VALUES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT authority_requirement_id, 'TB_AUTHORITY_REQUIREMENTS', dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_REQUIREMENTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT reference_list_id, 'TB_REFERENCE_LISTS', dataCheckId, runId, SYSDATE
    FROM TB_REFERENCE_LISTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT rule_qualifier_id, 'TB_RULE_QUALIFIERS', dataCheckId, runId, SYSDATE
    FROM TB_RULE_QUALIFIERS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT zone_id, 'TB_ZONES', dataCheckId, runId, SYSDATE
    FROM TB_ZONES
    WHERE EU_ZONE_AS_OF_DATE < '01-Jan-1900');
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT authority_material_Set_id, 'TB_AUTHORITY_MATERIAL_SETS', dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_MATERIAL_SETS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT authority_Rate_set_rate_id, 'TB_AUTHORITY_RATE_SET_RATES', dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_RATE_SET_RATES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');
    COMMIT;

    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT delivery_term_id, 'TB_DELIVERY_TERMS', dataCheckId, runId, SYSDATE
    FROM TB_DELIVERY_TERMS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');
    COMMIT;


    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT rule_id, 'TB_RULES', dataCheckId, runId, SYSDATE
    FROM TB_RULES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');
    COMMIT;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_ANY_98 finished.',runId);
    COMMIT;
END;
 
 
/