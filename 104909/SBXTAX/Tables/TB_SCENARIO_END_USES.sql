CREATE TABLE sbxtax.tb_scenario_end_uses (
  scenario_end_use_id NUMBER NOT NULL,
  scenario_id NUMBER NOT NULL,
  end_use VARCHAR2(100 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;