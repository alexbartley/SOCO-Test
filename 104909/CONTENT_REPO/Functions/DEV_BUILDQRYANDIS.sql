CREATE OR REPLACE FUNCTION content_repo.dev_BuildQryAndIs(searchVar IN VARCHAR2, dataCol IN varchar2) 
RETURN VARCHAR2 IS
/**
 *  Build AND / IN, NULL set for a list of values and a specified column
 *  Example: SELECT dev_BuildQryAndIs(SEARCHVAR=>'3,4,5,6,7,10', DATACOL=>'tbl.myColumn') FROM dual
 *  Function was first used for list of numbers and would build a col = null when
 *  value is less than 0 or = when a single number is used.
 *  (could be expanded with a parameter for what operator should be used eq. lt. etc) 
 *  '' would be a blank and no AND statement would be built
 */
    srchI varchar2(64);
  BEGIN
    IF LENGTH(searchVar)>0 THEN
      IF REGEXP_COUNT(searchVar, ',', 1, 'i') > 0 THEN
        srchI := ' AND '||dataCol||' IN('||searchVar||')';
      ELSE
        -- cluge
        IF TO_NUMBER(searchVar)>0 THEN
          srchI :=' AND '||dataCol||' = '||searchVar;
        ELSE
          srchI :=' AND '||dataCol||' is null ';
        END IF;
      END IF;
    ELSE
      srchI:=' ';
    END IF;
    RETURN srchI;
END dev_BuildQryAndIs;
 
 
 
 
/