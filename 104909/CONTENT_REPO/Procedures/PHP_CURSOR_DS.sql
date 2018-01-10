CREATE OR REPLACE PROCEDURE content_repo."PHP_CURSOR_DS" (entered_by IN NUMBER DEFAULT 3, refTrans OUT SYS_REFCURSOR) IS
    BEGIN
        -- Build
        OPEN refTrans FOR SELECT * FROM juris_tax_impositions_v
                        WHERE entered_by = entered_by;
        -- cursor is open
END php_cursor_ds;

 
 
/