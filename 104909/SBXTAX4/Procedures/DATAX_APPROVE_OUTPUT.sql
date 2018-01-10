CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_APPROVE_OUTPUT"
   ( thomsonReutersUserId IN VARCHAR2, userSignature IN VARCHAR2, dataCheckId IN NUMBER, primaryKey IN NUMBER, runId IN NUMBER)
   IS
   signatureId NUMBER;
   approved VARCHAR2(50);
   verified VARCHAR(50);
   authLevel VARCHAR2(50);
BEGIN
    IF dataCheckId IS NULL THEN
        INSERT INTO datax_records (recorded_message, run_id)  VALUES ('dataCheckId must be supplied. Unable to approve output for '||runId,-1);
        COMMIT;

   ELSE
       SELECT approval_signature_id, authorize_type
       INTO signatureId, authLevel
       FROM datax_approval_signatures
       WHERE thomson_reuters_uid = thomsonReutersUserId
       AND signature = userSignature;

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
    VALUES ('No approval signature was found for '||thomsonReutersUserId,-1);
    COMMIT;
    RAISE;
END; -- Procedure


 
 
 
/