CREATE TABLE sbxtax3.ht_alloc_buckets (
  allocation_id NUMBER(10),
  allocation_percent NUMBER(31,10),
  alloc_bucket_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "NAME" VARCHAR2(100 BYTE),
  previous_alloc_bucket_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_alloc_bucket_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;