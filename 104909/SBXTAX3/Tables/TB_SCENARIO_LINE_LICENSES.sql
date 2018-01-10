CREATE TABLE sbxtax3.tb_scenario_line_licenses (
  scenario_line_license_id NUMBER(10) NOT NULL,
  scenario_line_id NUMBER(10) NOT NULL,
  license_number VARCHAR2(100 BYTE) NOT NULL,
  license_type VARCHAR2(100 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;