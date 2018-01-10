CREATE TABLE crapp_admin.user_external_reference_system (
  "ID" NUMBER NOT NULL,
  user_id NUMBER NOT NULL,
  external_reference_system_id NUMBER NOT NULL,
  username VARCHAR2(32 CHAR) NOT NULL,
  "PASSWORD" VARCHAR2(128 CHAR) NOT NULL
) 
TABLESPACE crapp_admin;