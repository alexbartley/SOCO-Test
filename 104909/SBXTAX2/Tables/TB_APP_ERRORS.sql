CREATE TABLE sbxtax2.tb_app_errors (
  error_id NUMBER(10) NOT NULL,
  error_num VARCHAR2(240 BYTE) NOT NULL,
  error_severity VARCHAR2(25 BYTE) NOT NULL,
  title VARCHAR2(80 BYTE) NOT NULL,
  description VARCHAR2(2000 BYTE) NOT NULL,
  cause VARCHAR2(2000 BYTE) NOT NULL,
  "ACTION" VARCHAR2(2000 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "CATEGORY" VARCHAR2(40 BYTE),
  merchant_id NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;