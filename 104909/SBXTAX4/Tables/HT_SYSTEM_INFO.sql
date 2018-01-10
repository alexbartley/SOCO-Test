CREATE TABLE sbxtax4.ht_system_info (
  created_by NUMBER(10),
  creation_date DATE,
  info VARCHAR2(100 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "NAME" VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  system_info_id NUMBER(10),
  aud_system_info_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;