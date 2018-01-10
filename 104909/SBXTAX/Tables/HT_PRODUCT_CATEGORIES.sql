CREATE TABLE sbxtax.ht_product_categories (
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(250 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  notc VARCHAR2(20 BYTE),
  parent_product_category_id NUMBER(10),
  prodcode VARCHAR2(50 BYTE),
  product_category_id NUMBER(10),
  product_group_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_product_category_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;