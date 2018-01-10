CREATE OR REPLACE PROCEDURE sbxtax."CT_IMPORT_CSV"
   ( filename IN VARCHAR2)
   IS

    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    lineCounter NUMBER := 1;
BEGIN
    DELETE FROM CT_TEMP;
    COMMIT;
    ftype := UTL_FILE.fopen('C:\TEMP', filename, 'R', 32767 );

    IF UTL_FILE.is_open(ftype) THEN
        LOOP
          BEGIN
            UTL_FILE.get_line(ftype, fileLine, 32767 );
            IF fileLine IS NULL THEN
              EXIT;
            END IF;

            INSERT INTO CT_TEMP(filename, line_number, file_line) VALUES(filename, lineCounter, fileLine);

            lineCounter := lineCounter+1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              EXIT;
          END;
        END LOOP;
    END IF;
END;


 
 
/