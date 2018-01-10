CREATE TABLE sbxtax2.ht_allocations (
  allocation_id NUMBER(10),
  alloc_group_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  distribution_method VARCHAR2(20 BYTE),
  distribution_type VARCHAR2(20 BYTE),
  end_date DATE,
  is_integer_quantity VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "NAME" VARCHAR2(100 BYTE),
  rounding_rule VARCHAR2(20 BYTE),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_allocation_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;