CREATE TABLE sbxtax4.tb_app_errors (
  error_id NUMBER NOT NULL,
  error_num VARCHAR2(240 CHAR) NOT NULL,
  error_severity VARCHAR2(25 CHAR) NOT NULL,
  title VARCHAR2(80 CHAR) NOT NULL,
  description VARCHAR2(2000 CHAR) NOT NULL,
  cause VARCHAR2(2000 CHAR) NOT NULL,
  "ACTION" VARCHAR2(2000 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "CATEGORY" VARCHAR2(40 CHAR),
  merchant_id NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax
LOB ("ACTION") STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (cause) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);