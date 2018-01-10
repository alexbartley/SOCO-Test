CREATE OR REPLACE PACKAGE content_repo."ERRLOGGER"
IS
   c_table    CONSTANT PLS_INTEGER := 1;                   -- Default
   c_file     CONSTANT PLS_INTEGER := 2;
   c_screen   CONSTANT PLS_INTEGER := 3;

   PROCEDURE handle (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL,
      logerr    IN   BOOLEAN := TRUE,
      reraise   IN   BOOLEAN := FALSE
   );

   PROCEDURE report_and_stop (err_in IN INTEGER := SQLCODE,
      msg_in IN VARCHAR2 := NULL);


   PROCEDURE report_and_go (err_in IN INTEGER := SQLCODE,
      msg_in IN VARCHAR2 := NULL);

   PROCEDURE raise (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL
   );

   PROCEDURE log (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL
   );

   PROCEDURE logto (
      target   IN   PLS_INTEGER,
      dir      IN   VARCHAR2 := NULL,
      file     IN   VARCHAR2 := NULL
   );

   FUNCTION logging_to
      RETURN PLS_INTEGER;
END errlogger;

 
 
/