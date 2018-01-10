CREATE TABLE sbxtax3.tb_date_determination_logic (
  date_determination_logic_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(2000 BYTE) NOT NULL,
  date_expression VARCHAR2(2000 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;