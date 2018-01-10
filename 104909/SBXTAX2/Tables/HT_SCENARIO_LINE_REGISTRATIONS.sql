CREATE TABLE sbxtax2.ht_scenario_line_registrations (
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  registration_number VARCHAR2(50 BYTE),
  "ROLE" VARCHAR2(2 BYTE),
  scenario_line_id NUMBER(10),
  scenario_line_registration_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_scenario_line_reg_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;