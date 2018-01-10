CREATE OR REPLACE PROCEDURE sbxtax3.ct_update_zone_authorities
   IS
   affected NUMBER;
   executionDate DATE := sysdate;
   loggingMessage VARCHAR2(4000);
BEGIN
    UPDATE ct_zone_authorities
    SET creation_Date = SYSDATE-1
    WHERE creation_Date IS NULL;

    DELETE FROM ct_zone_authorities zt
    WHERE NOT EXISTS (
        SELECT 1
        FROM tb_zone_authorities
        WHERE zone_authority_id = zt.zone_authority_id
        );
    affected := SQL%ROWCOUNT;   
    COMMIT;
    
    INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
    VALUES ('CT_UPDATE_ZONE_AUTHORITIES',executionDate,to_char(affected)||' records deleted from CT_ZONE_AUTHORITIES because they no longer exist in TB_ZONE_AUTHORITIES by ZONE_AUTHORITY_ID.');
    COMMIT;
    affected := 0;
    DELETE FROM ct_zone_authorities zt
    WHERE NOT EXISTS (
        SELECT 1
        FROM tb_authorities
        WHERE name = zt.authority_name
        );
    affected := SQL%ROWCOUNT;   
    COMMIT;
    
    INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
    VALUES ('CT_UPDATE_ZONE_AUTHORITIES',executionDate,to_char(affected)||' records deleted from CT_ZONE_AUTHORITIES because they no longer exist in TB_ZONE_AUTHORITIES by AUTHORITY_ID.');
    COMMIT;
    affected := 0;
    CT_POPULATE_ZONE_AUTHORITIES();
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_UPDATE_ZONE_AUTHORITIES',SYSDATE,loggingMessage);
END; -- Procedure
 
 
/