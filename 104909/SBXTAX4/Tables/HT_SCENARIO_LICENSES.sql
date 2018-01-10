CREATE TABLE sbxtax4.ht_scenario_licenses (
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  license_number VARCHAR2(100 BYTE),
  license_type VARCHAR2(100 BYTE),
  scenario_id NUMBER(10),
  scenario_license_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_scenario_license_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;