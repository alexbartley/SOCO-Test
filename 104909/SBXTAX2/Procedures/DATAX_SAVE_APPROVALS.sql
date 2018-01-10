CREATE OR REPLACE PROCEDURE sbxtax2.datax_save_approvals
   ( inputString IN VARCHAR2)
   IS
    tlrId VARCHAR2(20);
    userName VARCHAR2(50);
    primaryKey VARCHAR2(50);
    dataCheckId VARCHAR2(50);
    newInputString VARCHAR2(4000);
    no_user VARCHAR2(100);
   errorMessage VARCHAR2(1000);
   errorCode VARCHAR2(10);
BEGIN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES ('InputString for Approvals:'||inputString,-1);
        COMMIT;
    newInputString := inputString;
    tlrId := SUBSTR(inputString,INSTR(inputString,'approver=')+9,INSTR(inputString,'/')-INSTR(inputString,'approver=')-9);
    userName := SUBSTR(inputString,INSTR(inputString,'/')+1,INSTR(inputString,';')-INSTR(inputString,'/')-1);
    dataCheckId := SUBSTR(inputString,INSTR(inputString,'dcid=')+5,INSTR(inputString,';',INSTR(inputString,'dcid='))-INSTR(inputString,'dcid=')-5);
    newInputString := SUBSTR(newInputString,INSTR(inputString,'pk='));
WHILE(INSTR(newInputString,';') > 4) LOOP
    primaryKey := SUBSTR(newInputString,INSTR(newInputString,'pk=')+3,INSTR(newInputString,';',INSTR(newInputString,'pk='))-INSTR(newInputString,'pk=')-3);
    --newInputString := SUBSTR(newInputString,INSTR(newInputString,';',INSTR(newInputString,'pk='))+1);
    newInputString := SUBSTR(newInputString,INSTR(newInputString,';',INSTR(newInputString,'pk=')+1)+1);
    IF (NVL(primaryKey,'dcid') NOT IN ('approver','dcid','user','sig')) THEN
        datax_approve_output(tlrId,userName,dataCheckId,to_number(primaryKey),null);
    END IF;
END LOOP;

EXCEPTION WHEN OTHERS THEN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES ('Unable to Save Approvals',-1);
        COMMIT;
        errorCode := SQLCODE;
        errorMessage := SQLERRM;
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES (errorCode||':'||SUBSTR(errorMessage, 1, 993),-1);
        COMMIT;
        raise_application_error(-20022,'Unable to locate Approver.');

END; -- Procedure
 
 
/