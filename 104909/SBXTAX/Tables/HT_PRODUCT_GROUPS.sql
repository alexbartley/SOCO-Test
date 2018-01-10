CREATE TABLE sbxtax.ht_product_groups (
  content_type VARCHAR2(50 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(200 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "NAME" VARCHAR2(100 BYTE),
  product_group_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_product_group_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;