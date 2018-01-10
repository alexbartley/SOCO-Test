CREATE TABLE sbxtax3.tb_countries (
  country_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(50 BYTE) NOT NULL,
  code_2char VARCHAR2(2 BYTE) NOT NULL,
  code_3char VARCHAR2(3 BYTE) NOT NULL,
  code_num VARCHAR2(3 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;