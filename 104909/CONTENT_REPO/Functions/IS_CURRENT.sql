CREATE OR REPLACE FUNCTION content_repo."IS_CURRENT"
  ( record_rid_i IN NUMBER, entity_next_rid_i IN NUMBER, record_next_rid_i IN NUMBER)
  RETURN  NUMBER IS
BEGIN
--
    IF record_rid_i < NVL(entity_next_rid_i,999999999999) THEN
        RETURN 1;
    ELSE
        RETURN  0;
    END IF;
END;

 
 
/