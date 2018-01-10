CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_144
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "144" name="144: JAVA: Check for circular contributing authorities
   countOf NUMBER;
   dataCheckId NUMBER := -678;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_144 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    --Doesn't matter what is 'selected', this DataCheck is looking for the for:
    --ORA-01436 CONNECT BY loop in user data. Cause: The condition specified in a CONNECT BY clause caused a loop in the query
    SELECT COUNT(*)
    INTO countOf
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND a.authority_id in (
        SELECT authority_id
        FROM tb_contributing_authorities ca
        START WITH ca.authority_id = a.authority_id
        CONNECT BY PRIOR ca.this_authority_id = ca.authority_id
        );

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_144 finished.',runId);
    COMMIT;

    EXCEPTION
       WHEN OTHERS THEN
        IF SQLCODE = '1436' THEN
            INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date)
            VALUES (1, dataCheckId, runId, SYSDATE);
        END IF;
END;
 
 
/