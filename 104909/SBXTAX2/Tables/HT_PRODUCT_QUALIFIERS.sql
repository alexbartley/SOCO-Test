CREATE TABLE sbxtax2.ht_product_qualifiers (
  commodity_code VARCHAR2(50 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "NAME" VARCHAR2(100 BYTE),
  ordering NUMBER(10),
  product_code VARCHAR2(100 BYTE),
  product_qualifier_group_id NUMBER(10),
  product_qualifier_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  transaction_type VARCHAR2(2 BYTE),
  aud_product_qualifier_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;