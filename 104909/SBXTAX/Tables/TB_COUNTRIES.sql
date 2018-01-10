CREATE TABLE sbxtax.tb_countries (
  country_id NUMBER NOT NULL,
  "NAME" VARCHAR2(50 CHAR) NOT NULL,
  code_2char VARCHAR2(2 CHAR) NOT NULL,
  code_3char VARCHAR2(3 CHAR) NOT NULL,
  code_num VARCHAR2(3 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;