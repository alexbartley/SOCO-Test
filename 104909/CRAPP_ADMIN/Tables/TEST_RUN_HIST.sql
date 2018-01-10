CREATE TABLE crapp_admin.test_run_hist (
  "ID" NUMBER(11),
  group_type VARCHAR2(20 CHAR) NOT NULL,
  group_type_id NUMBER(11),
  tester NUMBER(11) NOT NULL,
  run_start NUMBER(10) NOT NULL,
  run_stop NUMBER(10),
  result VARCHAR2(20 CHAR)
) 
TABLESPACE crapp_admin;
COMMENT ON COLUMN crapp_admin.test_run_hist.group_type IS 'all, group, single';