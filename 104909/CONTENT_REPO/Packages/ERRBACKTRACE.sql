CREATE OR REPLACE PACKAGE content_repo."ERRBACKTRACE"
IS
/*
| Overview: bt provides structured access to the information
|           returned by DBMS_UTILITY.format_error_backtrace.
*/
   TYPE error_rt IS RECORD (
      program_owner   all_objects.owner%TYPE
    , program_name    all_objects.object_name%TYPE
    , line_number     PLS_INTEGER
   );

--
-- Parse a line with this format:
-- ORA-NNNNN: at "SCHEMA.PROGRAM", line NNN
--
   FUNCTION info (backtrace_in IN VARCHAR2)
      RETURN error_rt;

   PROCEDURE show_info (backtrace_in IN VARCHAR2);
END errbacktrace;

 
 
/