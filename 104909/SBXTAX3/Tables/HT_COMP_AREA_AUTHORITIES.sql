CREATE TABLE sbxtax3.ht_comp_area_authorities (
  authority_id NUMBER(10),
  compliance_area_auth_id NUMBER(10),
  compliance_area_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_compliance_area_auth_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;