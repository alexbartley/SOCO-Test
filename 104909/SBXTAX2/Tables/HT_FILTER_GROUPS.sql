CREATE TABLE sbxtax2.ht_filter_groups (
  copy_of_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(4000 BYTE),
  end_date DATE,
  filter_group_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  start_date DATE,
  status VARCHAR2(1 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_filter_group_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;