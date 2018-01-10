CREATE TABLE sbxtax4.ht_license_keys (
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  license_key_body VARCHAR2(40 CHAR),
  license_key_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_license_key_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 CHAR) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;