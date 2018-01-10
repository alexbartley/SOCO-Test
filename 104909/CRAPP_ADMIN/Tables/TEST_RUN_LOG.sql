CREATE TABLE crapp_admin.test_run_log (
  "ID" NUMBER(11) NOT NULL,
  run_id NUMBER(11) NOT NULL,
  msg_type VARCHAR2(20 CHAR) NOT NULL,
  message LONG,
  test_id NUMBER(11),
  "SUCCESS" NUMBER(1),
  os VARCHAR2(20 CHAR),
  browser VARCHAR2(20 CHAR),
  browser_version VARCHAR2(20 CHAR),
  PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE crapp_admin
) 
TABLESPACE crapp_admin;
COMMENT ON COLUMN crapp_admin.test_run_log.msg_type IS 'logic, test';