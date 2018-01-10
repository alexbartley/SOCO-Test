CREATE TABLE sbxtax4.ht_alloc_bucket_actions (
  alloc_bucket_action_id NUMBER(10),
  alloc_bucket_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "OPERATOR" VARCHAR2(15 BYTE),
  prev_alloc_bucket_action_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  "VALUE" VARCHAR2(250 BYTE),
  value_xml_element VARCHAR2(250 BYTE),
  xml_element VARCHAR2(250 BYTE),
  aud_alloc_bucket_action_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;