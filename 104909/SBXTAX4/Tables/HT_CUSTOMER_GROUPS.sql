CREATE TABLE sbxtax4.ht_customer_groups (
  created_by NUMBER(10),
  creation_date DATE,
  customer_group_id NUMBER(10),
  description VARCHAR2(500 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_customer_group_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;