CREATE OR REPLACE PROCEDURE sbxtax2.datax_any_98_1
   (runId IN OUT NUMBER)
   IS
   --<data_check id="98.1" name="Check for Invalid Dates" >
   --98_1 is for F because it does not have the same table list as G
   dataCheckId NUMBER := -785;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_ANY_98_1 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT authority_logic_group_xref_id, dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_LOGIC_GROUP_XREF
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;


    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT rate_id, dataCheckId, runId, SYSDATE
    FROM TB_RATES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;

    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT authority_logic_element_id, dataCheckId, runId, SYSDATE
    FROM TB_AUTHORITY_LOGIC_ELEMENTS
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900' );
    COMMIT;




    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT zone_id, dataCheckId, runId, SYSDATE
    FROM TB_ZONES
    WHERE EU_ZONE_AS_OF_DATE < '01-Jan-1900');
    COMMIT;



    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT rule_id, dataCheckId, runId, SYSDATE
    FROM TB_RULES
    WHERE START_DATE < '01-Jan-1900'
    OR END_DATE < '01-Jan-1900');
    COMMIT;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_ANY_98_1 finished.',runId);
    COMMIT;
END;
 
 
/