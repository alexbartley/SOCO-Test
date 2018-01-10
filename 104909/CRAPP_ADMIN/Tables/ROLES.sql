CREATE TABLE crapp_admin."ROLES" (
  "ID" NUMBER NOT NULL,
  status NUMBER DEFAULT 0,
  "NAME" VARCHAR2(255 CHAR),
  parent_role_id NUMBER,
  "PARENT" VARCHAR2(255 CHAR),
  role_id VARCHAR2(255 CHAR),
  description VARCHAR2(1000 CHAR),
  CONSTRAINT crapp_roles_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE crapp_admin
) 
TABLESPACE crapp_admin;