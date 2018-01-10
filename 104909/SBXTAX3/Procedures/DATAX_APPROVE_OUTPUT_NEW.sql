CREATE OR REPLACE PROCEDURE sbxtax3.datax_approve_output_new
   ( accessId IN VARCHAR2, dataCheckId IN NUMBER, primaryKey IN NUMBER, runId IN NUMBER)
   IS
   approved VARCHAR2(50);
   verified VARCHAR(50);
   authLevel VARCHAR2(50);
   thomsonReutersUserId VARCHAR2(100);
BEGIN
    IF dataCheckId IS NULL THEN
        INSERT INTO datax_records (recorded_message, run_id)  VALUES ('dataCheckId must be supplied. Unable to approve output for '||runId,-1);
        COMMIT;

   ELSE
       SELECT  authorize_type, emp_id
       INTO authLevel, thomsonReutersUserId
       FROM ct_access
       WHERE access_id = accessId;

       IF authLevel = 'APPROVER' THEN
           IF primaryKey IS NULL AND runId IS NOT NULL THEN
               UPDATE datax_check_output
               SET reviewed_Approved = thomsonReutersUserId, verified = COALESCE(verified,thomsonReutersUserId)
               WHERE data_check_id = dataCheckId
               AND run_id = runId
               AND reviewed_Approved IS NULL;
               COMMIT;
           ELSIF primaryKey IS NOT NULL THEN
               UPDATE datax_check_output
               SET reviewed_Approved = thomsonReutersUserId, verified = COALESCE(verified,thomsonReutersUserId)
               WHERE data_check_id = dataCheckId
               AND primary_key = primaryKey
               AND reviewed_Approved IS NULL;
               COMMIT;
           END IF;
       ELSE
           IF primaryKey IS NULL AND runId IS NOT NULL THEN
               UPDATE datax_check_output
               SET verified = thomsonReutersUserId
               WHERE data_check_id = dataCheckId
               AND run_id = runId
               AND verified IS NULL;
               COMMIT;
           ELSIF primaryKey IS NOT NULL THEN
               UPDATE datax_check_output
               SET verified = thomsonReutersUserId
               WHERE data_check_id = dataCheckId
               AND primary_key = primaryKey
               AND verified IS NULL;
               COMMIT;
           END IF;
       END IF;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('No approval signature was found for '||accessId,-1);
    COMMIT;
    RAISE;
END; -- Procedure
 
 
/