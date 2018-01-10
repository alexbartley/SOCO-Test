CREATE OR REPLACE PROCEDURE sbxtax."DATAX_ANY_98"
   (runId IN OUT NUMBER)
   IS
   --<data_check id="98" name="Check for Invalid Dates" >
   dataCheckId NUMBER := -639;
   vlocal_step varchar2(100);
   err_num number;
   err_msg varchar2(4000);
BEGIN

    vlocal_step := 'DATAX_ANY_98 STEP 0';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_ANY_98 started.',runId) RETURNING run_id INTO runId;
    COMMIT;

    vlocal_step := 'DATAX_ANY_98 STEP 1';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT authority_logic_group_xref_id, dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_LOGIC_GROUP_XREF
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );

    vlocal_step := 'DATAX_ANY_98 STEP 2';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT material_Set_list_id, dataCheckId, runId, SYSDATE
    FROM TB_MATERIAL_SET_LISTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );

    vlocal_step := 'DATAX_ANY_98 STEP 3';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT rate_id, dataCheckId, runId, SYSDATE
    FROM TB_RATES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );

    vlocal_step := 'DATAX_ANY_98 STEP 4';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT authority_logic_element_id, dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_LOGIC_ELEMENTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );

    vlocal_step := 'DATAX_ANY_98 STEP 5';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT date_determination_rule_id, dataCheckId, runId, SYSDATE
    FROM TB_DATE_DETERMINATION_RULES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );

    vlocal_step := 'DATAX_ANY_98 STEP 6';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT contributing_authority_id, dataCheckId, runId, SYSDATE
    FROM TB_CONTRIBUTING_AUTHORITIES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );

    vlocal_step := 'DATAX_ANY_98 STEP 7';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT rule_output_id, dataCheckId, runId, SYSDATE
    FROM TB_RULE_OUTPUTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );

    vlocal_step := 'DATAX_ANY_98 STEP 8';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT material_set_list_product_id, dataCheckId, runId, SYSDATE
    FROM TB_MATERIAL_SET_LIST_PRODUCTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');

    vlocal_step := 'DATAX_ANY_98 STEP 9';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT reference_value_id, dataCheckId, runId, SYSDATE
    FROM TB_REFERENCE_VALUES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );

    vlocal_step := 'DATAX_ANY_98 STEP 10';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT authority_requirement_id, dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_REQUIREMENTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );

    vlocal_step := 'DATAX_ANY_98 STEP 11';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT reference_list_id, dataCheckId, runId, SYSDATE
    FROM TB_REFERENCE_LISTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');

    vlocal_step := 'DATAX_ANY_98 STEP 12';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT rule_qualifier_id, dataCheckId, runId, SYSDATE
    FROM TB_RULE_QUALIFIERS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');

    vlocal_step := 'DATAX_ANY_98 STEP 13';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT zone_id, dataCheckId, runId, SYSDATE
    FROM TB_ZONES
    WHERE EU_ZONE_AS_OF_DATE < '01-Jan-1900');

    vlocal_step := 'DATAX_ANY_98 STEP 14';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT authority_material_Set_id, dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_MATERIAL_SETS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );

    vlocal_step := 'DATAX_ANY_98 STEP 15';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT authority_Rate_set_rate_id, dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_RATE_SET_RATES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');
    COMMIT;

    vlocal_step := 'DATAX_ANY_98 STEP 16';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT delivery_term_id, dataCheckId, runId, SYSDATE
    FROM TB_DELIVERY_TERMS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');

    vlocal_step := 'DATAX_ANY_98 STEP 17';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT rule_id, dataCheckId, runId, SYSDATE
    FROM TB_RULES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');

    vlocal_step := 'DATAX_ANY_98 STEP 18';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_ANY_98 finished.',runId);
    COMMIT;

EXCEPTION
WHEN OTHERS THEN
      err_num := SQLCODE;
      err_msg := SUBSTR(SQLERRM, 1, 4000);

    INSERT INTO data_check_err_log(dataCheckId, runId, errcode, errmsg, step_number, entered_date, entered_by)
    VALUES( dataCheckId, runId, err_num, err_msg, vlocal_step, SYSDATE, -1);
    COMMIT;
END;



 
/