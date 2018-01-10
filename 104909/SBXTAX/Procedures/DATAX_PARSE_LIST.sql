CREATE OR REPLACE PROCEDURE sbxtax."DATAX_PARSE_LIST"
   ( inputString IN VARCHAR2, runId IN NUMBER)
   IS
    newInputString VARCHAR2(4000);
    dataCheckId NUMBER;
    planName VARCHAR2(100);
BEGIN
newInputString := inputString;
planName := 'CUSTOM-'||to_char(sysdate, 'yyyy-mm-dd');
WHILE(INSTR(newInputString,';') > 4) LOOP
    dataCheckId := substr(newInputString,1,instr(newInputString,';')-1);
    INSERT INTO datax_run_executions(run_id,data_check_id,plan_name,execution_Date)
    VALUES (runId, dataCheckId, planName,'01-Jan-1900');
    COMMIT;
    newInputString := substr(newInputString,instr(newInputString,';')+1);
END LOOP;

END; -- Procedure


 
 
/