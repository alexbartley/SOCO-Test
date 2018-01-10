CREATE TABLE sbxtax.tb_states (
  state_id NUMBER NOT NULL,
  code VARCHAR2(2 CHAR) NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  us_state VARCHAR2(1 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;