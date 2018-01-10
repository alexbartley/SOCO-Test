CREATE TABLE sbxtax4.tb_scenario_licenses (
  scenario_license_id NUMBER NOT NULL,
  scenario_id NUMBER NOT NULL,
  license_number VARCHAR2(100 CHAR) NOT NULL,
  license_type VARCHAR2(100 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;