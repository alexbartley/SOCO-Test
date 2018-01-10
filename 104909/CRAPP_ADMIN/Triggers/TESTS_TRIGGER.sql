CREATE OR REPLACE TRIGGER crapp_admin."TESTS_TRIGGER"
BEFORE INSERT ON crapp_admin.test_tests
FOR EACH ROW

BEGIN
  SELECT tests_seq.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
/