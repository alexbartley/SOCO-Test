CREATE TABLE sbxtax2.ht_filters (
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(4000 BYTE),
  display_order NUMBER(10),
  filter_group_id NUMBER(10),
  filter_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "NAME" VARCHAR2(100 BYTE),
  ordering NUMBER(10),
  parent_filter_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_filter_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;