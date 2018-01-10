CREATE OR REPLACE PROCEDURE sbxtax3.datax_extract_proc_ddl
   IS
CURSOR datax_procs IS
SELECT object_name
FROM user_procedures up
WHERE object_name LIKE 'DATAX%'
AND object_type = 'PROCEDURE'
AND object_name NOT LIKE 'DATAX_QA_COMPARE'
AND NOT EXISTS (
    SELECT 1
    FROM datax_checks
    WHERE procedure_name = up.object_name
    AND nvl(tax_research_only,'N') = 'Y'
    );

filename VARCHAR2(100) := 'Datax_Procedures_DDL.sql';
ftype UTL_FILE.file_type;
selfschema VARCHAR2(100);
BEGIN

    SELECT SYS_CONTEXT( 'userenv', 'current_schema' ) 
    INTO selfschema
    FROM dual;
    
    ftype := UTL_FILE.fopen('C:\TEMP', filename, 'W');
    FOR p IN datax_procs LOOP 
        UTL_FILE.put(ftype,REPLACE(DBMS_METADATA.GET_DDL('PROCEDURE',p.object_name),'"'||selfschema||'"."'||p.object_name||'"',p.object_name));
        UTL_FILE.fflush(ftype);
        UTL_FILE.put_line(ftype,chr(13)||'/');
    END LOOP;
UTL_FILE.put_line(ftype,'exit');
UTL_FILE.fclose(ftype);

END; -- Procedure
 
 
/