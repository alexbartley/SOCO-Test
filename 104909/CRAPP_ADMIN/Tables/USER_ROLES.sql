CREATE TABLE crapp_admin.user_roles (
  "ID" NUMBER NOT NULL,
  user_id NUMBER NOT NULL,
  role_id VARCHAR2(32 CHAR) NOT NULL,
  active_date DATE,
  expire_date DATE,
  entered_by NUMBER,
  entered_date DATE,
  CONSTRAINT crapp_user_roles_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE crapp_admin
) 
TABLESPACE crapp_admin;