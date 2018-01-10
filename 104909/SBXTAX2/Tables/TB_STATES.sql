CREATE TABLE sbxtax2.tb_states (
  state_id NUMBER NOT NULL,
  code VARCHAR2(2 BYTE) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  us_state VARCHAR2(1 BYTE) NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;