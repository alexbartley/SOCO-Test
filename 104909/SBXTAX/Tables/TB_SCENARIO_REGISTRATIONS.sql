CREATE TABLE sbxtax.tb_scenario_registrations (
  scenario_registration_id NUMBER NOT NULL,
  scenario_id NUMBER NOT NULL,
  "ROLE" VARCHAR2(2 CHAR) NOT NULL,
  registration_number VARCHAR2(50 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;