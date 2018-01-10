CREATE OR REPLACE TRIGGER crapp_admin."RUN_LOG_TRIGGER"
BEFORE INSERT ON crapp_admin.test_run_log
FOR EACH ROW

BEGIN
  SELECT run_log_seq.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
/