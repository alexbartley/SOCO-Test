CREATE OR REPLACE PROCEDURE sbxtax2.ct_reports_execute (inputParameters IN VARCHAR2, filename IN OUT VARCHAR2)
   IS
   TYPE parameter_list IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(100);
   reportParameters parameter_list;
   nil VARCHAR2(1) :=0;
   localParameterString VARCHAR2(4000);
   paramPair VARCHAR2(1500);
   procedureCall VARCHAR2(4000);
   executeProc VARCHAR2(4000);
   pIndex VARCHAR2(500);
   jobId NUMBER;
   reportId NUMBER;
   loggingMessage VARCHAR2(4000);
BEGIN
    localParameterString  := SUBSTR(inputParameters,1,4000);
    
   IF (localParameterString IS NOT NULL) THEN
        WHILE (INSTR(localParameterString,'=') > 0) LOOP
            --each parameter name/value pair ends with a semi-colon
            paramPair := SUBSTR(localParameterString,1,INSTR(localParameterString,';')-1);
            --trim the original parameter string to remove the parameter pair extracted in previous line
            localParameterString := REPLACE(localParameterString,paramPair||';'); 
            --put the string on the left side of "=" in the parameter list as the parameter key
            --put the string on the right side of "=" in the parameter list as the parameter value
            reportParameters(SUBSTR(paramPair,1,INSTR(paramPair,'=')-1)) := SUBSTR(paramPair,INSTR(paramPair,'=')+1); 
        END LOOP;
   END IF;
   
   --locate the report requested, the requested report is the value of the "identify" parameter
   --generate a unique filename with Date/Time of the request
   SELECT report_id, output_filename||'-'||TO_CHAR(SYSDATE,'YYYYMMDD-HH24-MI-SS')||'.csv', procedure_call
   INTO reportId, filename, procedureCall
   FROM ct_report_library
   WHERE report_code = reportParameters('identify');

    --generate the Procedure call by replacing the skeleton Procedure call configured with the Report (in CT_REPORT_LIBRARY) with the user supplied values
    --Procedure variable name is expected to case-sensitive match a parameter name parsed from the inputParameters
   pIndex := reportParameters.FIRST;
   WHILE (pIndex IS NOT NULL) LOOP
        procedureCall := REPLACE(procedureCall,'${'||pIndex||'}',''''||reportParameters(pIndex)||'''');
        pIndex := reportParameters.NEXT(pIndex);
   END LOOP;
   procedureCall := REPLACE(procedureCall,'${filename}',''''||filename||'''');
   dbms_output.put_line(procedureCall);
   --Create a record in CT_REPORT_EXEC_HISTORY to track execution of the report
   INSERT INTO ct_report_exec_history(report_id,status,queued_Date, output_filename, exec_parameters)
   VALUES (reportId,'QUEUED',SYSDATE, filename, SUBSTR(procedureCall,INSTR(procedureCall,'(')+1,LENGTH(procedureCall)-INSTR(procedureCall,'(')-2));
   --Submit the Procedure call to the DBMS
   DBMS_JOB.SUBMIT(jobId, procedureCall, SYSDATE, null);
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REPORTS_EXECUTE',SYSDATE,loggingMessage);
END; -- Procedure
 
 
/