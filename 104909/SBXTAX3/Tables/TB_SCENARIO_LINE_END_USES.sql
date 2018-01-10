CREATE TABLE sbxtax3.tb_scenario_line_end_uses (
  scenario_line_end_use_id NUMBER(10) NOT NULL,
  scenario_line_id NUMBER(10) NOT NULL,
  end_use VARCHAR2(100 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;