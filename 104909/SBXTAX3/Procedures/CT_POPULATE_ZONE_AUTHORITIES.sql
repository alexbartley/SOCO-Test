CREATE OR REPLACE PROCEDURE sbxtax3.ct_populate_zone_authorities
   IS
    loggingMessage VARCHAR2(4000);
   executionDate DATE := sysdate;
   affected NUMBER;
BEGIN


   INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
   VALUES ('CT_POPULATE_ZONE_AUTHORITIES',executionDate,'Checking for records to insert...');
   COMMIT;

    INSERT INTO CT_ZONE_AUTHORITIES (
        merchant_id,primary_key,zone_1_id,zone_1_name,zone_1_level_id,zone_2_id,zone_2_name,zone_2_level_id,
        zone_3_id,zone_3_name,zone_3_level_id,zone_4_id,zone_4_name,zone_4_level_id,zone_5_id,zone_5_name,zone_5_level_id,
        zone_6_id,zone_6_name,zone_6_level_id,zone_7_id,zone_7_name,zone_7_level_id,
        tax_parent_zone,    eu_zone_as_of_date,    code_2char,    code_3char,    code_iso,    code_fips,    reverse_flag,
        terminator_flag,    default_flag,    range_min,    range_max, authority_name, zone_Authority_id, creation_Date,
        eu_exit_date, gcc_as_of_date, gcc_exit_date
    ) (
        SELECT zt.merchant_id,zt.primary_key,zt.zone_1_id,zt.zone_1_name,zt.zone_1_level_id,zt.zone_2_id,zt.zone_2_name,zt.zone_2_level_id,
        zt.zone_3_id,zt.zone_3_name,zt.zone_3_level_id,zt.zone_4_id,zt.zone_4_name,zt.zone_4_level_id,zt.zone_5_id,zt.zone_5_name,zt.zone_5_level_id,
        zt.zone_6_id,zt.zone_6_name,zt.zone_6_level_id,zt.zone_7_id,zt.zone_7_name,zt.zone_7_level_id,
        zt.tax_parent_zone,zt.eu_zone_as_of_date,zt.code_2char,zt.code_3char,zt.code_iso,zt.code_fips,zt.reverse_flag,
        zt.terminator_flag,zt.default_flag,zt.range_min,zt.range_max, a.name authority_name, za.zone_Authority_id, sysdate,
        zt.eu_exit_date, zt.gcc_as_of_date, zt.gcc_exit_date
        FROM tb_Authorities a, tb_Zone_authorities za, ct_zone_Tree zt
        WHERE za.authority_id = a.authority_id
        AND za.zone_id = zt.primary_key
        AND NOT EXISTS (
            SELECT 1
            FROM ct_Zone_Authorities cza
            WHERE cza.zone_authority_id = za.zone_authority_id
            )
    );
   affected := SQL%ROWCOUNT;
   COMMIT;
   INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
   VALUES ('CT_POPULATE_ZONE_AUTHORITIES',executionDate,to_char(affected)||' records inserted into CT_ZONE_AUTHORITIES.');
   COMMIT;
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_POPULATE_ZONE_AUTHORITIES',SYSDATE,loggingMessage);
END; -- Procedure
/