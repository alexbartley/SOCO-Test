CREATE OR REPLACE FUNCTION content_repo."IS_NUMBER" (
                str_in IN VARCHAR2
                ) RETURN NUMBER PARALLEL_ENABLE IS
   n NUMBER;
/*
|| Author:      Adrian Billington www.oracle-developer.net
|| Description: A couple of variations of an IS_NUMBER function.
||              This is a common approach that can certainly be found in at
||              least one well-known PL/SQL book.
|| Version:     1.0: original
||              1.1: removed deterministic keyword (thanks to Matthias Rogel)
|| -----------------------------------------------------------------------------
|| CRAPP: 2014
|| (Previously in a generic package)
|| SQL and PL/SQL version
*/
BEGIN
   n := TO_NUMBER(str_in);
   RETURN 1;
EXCEPTION
   WHEN VALUE_ERROR THEN
      RETURN 0;
END;
 
/