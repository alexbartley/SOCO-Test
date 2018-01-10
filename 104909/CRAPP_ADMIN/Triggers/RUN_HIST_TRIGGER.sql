CREATE OR REPLACE TRIGGER crapp_admin."RUN_HIST_TRIGGER"
BEFORE INSERT ON crapp_admin.test_run_hist
FOR EACH ROW

BEGIN
  SELECT run_hist_seq.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
/