CREATE TABLE sbxtax3.ht_reference_values (
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  reference_list_id NUMBER(10),
  reference_value_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  "VALUE" VARCHAR2(200 BYTE),
  aud_reference_value_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;