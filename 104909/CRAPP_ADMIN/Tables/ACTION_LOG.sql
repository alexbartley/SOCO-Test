CREATE TABLE crapp_admin.action_log (
  "ID" NUMBER NOT NULL,
  action_start TIMESTAMP(7) NOT NULL,
  action_end TIMESTAMP(7),
  status NUMBER,
  referrer VARCHAR2(2048 CHAR),
  entered_by NUMBER,
  "PARAMETERS" CLOB,
  process_id NUMBER,
  CONSTRAINT action_log_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE crapp_admin,
  CONSTRAINT action_log_fk1 FOREIGN KEY (entered_by) REFERENCES crapp_admin."USERS" ("ID")
) 
TABLESPACE crapp_admin
LOB ("PARAMETERS") STORE AS BASICFILE (
  ENABLE STORAGE IN ROW)
LOB (referrer) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);