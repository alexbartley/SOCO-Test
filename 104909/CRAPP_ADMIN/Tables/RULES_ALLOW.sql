CREATE TABLE crapp_admin.rules_allow (
  "ID" NUMBER NOT NULL,
  rule_id VARCHAR2(255 CHAR) NOT NULL,
  "ROLES" VARCHAR2(255 CHAR) NOT NULL,
  entered_by NUMBER,
  entered_date TIMESTAMP,
  status NUMBER DEFAULT 0,
  status_modified_date TIMESTAMP,
  CONSTRAINT rules_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE crapp_admin
) 
TABLESPACE crapp_admin;