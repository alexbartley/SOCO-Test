CREATE TABLE crapp_admin.test_group (
  "ID" NUMBER(11) NOT NULL,
  "NAME" VARCHAR2(30 CHAR),
  PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE crapp_admin
) 
TABLESPACE crapp_admin;