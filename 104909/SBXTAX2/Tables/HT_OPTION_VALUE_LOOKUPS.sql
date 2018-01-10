CREATE TABLE sbxtax2.ht_option_value_lookups (
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(200 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  option_lookup_id NUMBER(10),
  option_value_lookup_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  type_lookup_id NUMBER(10),
  "VALUE" VARCHAR2(200 BYTE),
  aud_option_value_lookup_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;