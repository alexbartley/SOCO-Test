CREATE TABLE crapp_admin."USERS" (
  "ID" NUMBER NOT NULL,
  username VARCHAR2(32 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  "PASSWORD" VARCHAR2(32 CHAR),
  email VARCHAR2(64 CHAR) NOT NULL,
  firstname VARCHAR2(32 CHAR) NOT NULL,
  lastname VARCHAR2(32 CHAR) NOT NULL,
  costcenter VARCHAR2(32 CHAR),
  company VARCHAR2(32 CHAR),
  marketgroup VARCHAR2(32 CHAR),
  mgoverride VARCHAR2(32 CHAR),
  paygroup VARCHAR2(32 CHAR),
  thomslocation VARCHAR2(32 CHAR),
  reset_token VARCHAR2(32 CHAR),
  reset_expire TIMESTAMP,
  CONSTRAINT crapp_users_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE crapp_admin
) 
TABLESPACE crapp_admin;