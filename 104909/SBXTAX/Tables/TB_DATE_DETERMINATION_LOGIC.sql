CREATE TABLE sbxtax.tb_date_determination_logic (
  date_determination_logic_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  description VARCHAR2(2000 CHAR) NOT NULL,
  date_expression VARCHAR2(2000 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax
LOB (date_expression) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);