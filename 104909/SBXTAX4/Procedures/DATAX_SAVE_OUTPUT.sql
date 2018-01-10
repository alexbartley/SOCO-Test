CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_SAVE_OUTPUT"
   ( dataCheckId IN NUMBER, runId IN NUMBER, primaryKey IN NUMBER, qaUserId IN NUMBER)
   IS
    orgRunId NUMBER := NULL;
BEGIN
    SELECT DISTINCT original_run_id
    INTO orgRunId
    FROM datax_output_save
    WHERE data_check_id = dataCheckId
    AND primary_key = primaryKey;

    INSERT INTO datax_output_save (data_check_id, original_run_id, primary_key, repeated_run_id)
    VALUES (dataCheckId, NVL(orgRunId,runId), primaryKey, runId);

   DELETE FROM datax_check_output
   WHERE data_check_id = dataCheckId
   AND run_id = runId
   AND primary_key = primaryKey
   AND reviewed_approved IS NULL;
   COMMIT;

   /* Commenting this out for QAE - 1762 as we are storing any data into this table.

   DELETE FROM datax_check_misc_output
   WHERE data_check_id = dataCheckId
   AND run_id = runId;
   COMMIT;
   */

   INSERT INTO datax_records (recorded_message, run_id)
   VALUES ('QA User: '||qaUserId||' saved output result for DataCheck: '||dataCheckId||' for Record: '||primaryKey||'.',runId);
END; -- Procedure





 
/