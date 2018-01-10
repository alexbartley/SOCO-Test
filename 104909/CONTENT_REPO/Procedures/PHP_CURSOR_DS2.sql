CREATE OR REPLACE PROCEDURE content_repo."PHP_CURSOR_DS2" (sName IN VARCHAR2, refTrans OUT SYS_REFCURSOR) IS
    BEGIN
        -- Build
        OPEN refTrans FOR SELECT * FROM commodities WHERE upper(name) LIKE '%'||upper(sName)||'%';
        -- cursor is open
END php_cursor_ds2;

 
 
/