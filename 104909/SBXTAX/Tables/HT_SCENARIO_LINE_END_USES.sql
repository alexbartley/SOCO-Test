CREATE TABLE sbxtax.ht_scenario_line_end_uses (
  created_by NUMBER(10),
  creation_date DATE,
  end_use VARCHAR2(100 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  scenario_line_end_use_id NUMBER(10),
  scenario_line_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_scenario_line_end_use_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;