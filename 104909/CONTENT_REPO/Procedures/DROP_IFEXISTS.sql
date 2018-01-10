CREATE OR REPLACE PROCEDURE content_repo."DROP_IFEXISTS" 
/*
#
# Procedure: DROP_IFEXISTS 01-JUL-13 tnn
# This is part of a generic package but for the QA test purposes this should
# probably be a single procedure.
#
#############################################################################
#
# Action: Compile, use
#
# Drop object if it exists
# Parameters: type of object, name
# Note: User objects - not across schema
#
#
*/
(pv_type VARCHAR2, pv_name VARCHAR2, pv_owner VARCHAR2)
    AUTHID CURRENT_USER
IS
    -- String for DDL command.
    sql_text          VARCHAR2 (2000);
    owner_exception   EXCEPTION;
    vcnt              NUMBER := 0;

    -- Find object to drop cursor
    CURSOR find_object (
        cv_type     VARCHAR2,
        cv_name     VARCHAR2,
        cv_owner    VARCHAR2)
    IS
        SELECT ao.object_name, ao.object_type, ao.owner
          FROM all_objects ao
         WHERE     ao.object_name = UPPER (cv_name)
               AND ao.object_type = UPPER (cv_type)
               AND ao.owner = UPPER (cv_owner);
BEGIN
    SELECT COUNT (1)
      INTO vcnt
      FROM all_users
     WHERE username = UPPER (pv_owner)
       AND oracle_maintained = 'N';

    IF pv_owner IS NULL OR vcnt = 0
    THEN
        RAISE owner_exception;
    ELSE
        FOR i IN find_object (pv_type, pv_name, pv_owner)
        LOOP
            -- Check for a table object - append cascade constraints.
            IF i.object_type = 'TABLE'
            THEN
                sql_text := 'DROP ' || i.object_type || ' '|| i.owner || '.' || i.object_name|| ' CASCADE CONSTRAINTS';
            ELSE
                sql_text := 'DROP ' || i.object_type || ' ' || i.owner || '.' || i.object_name;
            END IF;
            -- Run
            DBMS_OUTPUT.put_line (sql_text);

            EXECUTE IMMEDIATE sql_text;
        END LOOP;
    END IF;
EXCEPTION
    WHEN owner_exception
    THEN
        raise_application_error (-20998,'Owner name is incorrect. Please correct it and try again.');
    WHEN OTHERS
    THEN
        raise_application_error ( -20999, 'The object is currently being used by other process. Please try removing object after some time.');
END drop_ifexists;
/