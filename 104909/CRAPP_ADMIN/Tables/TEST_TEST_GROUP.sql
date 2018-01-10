CREATE TABLE crapp_admin.test_test_group (
  "ID" NUMBER(11) NOT NULL,
  test_id NUMBER(11) NOT NULL,
  "GROUP_ID" NUMBER(11) NOT NULL,
  PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE crapp_admin
) 
TABLESPACE crapp_admin;