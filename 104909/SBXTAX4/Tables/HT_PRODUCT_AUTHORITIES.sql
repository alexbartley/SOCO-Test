CREATE TABLE sbxtax4.ht_product_authorities (
  authority_id NUMBER(10),
  authority_type_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  "EXEMPT" VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  override_locals VARCHAR2(1 BYTE),
  product_authority_id NUMBER(10),
  product_category_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  zone_id NUMBER(10),
  aud_product_authority_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;