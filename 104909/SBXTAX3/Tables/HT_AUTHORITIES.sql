CREATE TABLE sbxtax3.ht_authorities (
  admin_zone_level_id NUMBER(10),
  authority_category VARCHAR2(100 BYTE),
  authority_id NUMBER(10),
  authority_type_id NUMBER(10),
  content_type VARCHAR2(50 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(100 BYTE),
  distance_sales_threshold NUMBER(31,5),
  effective_zone_level_id NUMBER(10),
  erp_tax_code VARCHAR2(200 BYTE),
  invoice_description VARCHAR2(100 BYTE),
  is_custom_authority VARCHAR2(1 BYTE),
  is_template VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  location_code VARCHAR2(50 BYTE),
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  official_name VARCHAR2(100 BYTE),
  product_group_id NUMBER(10),
  region_code VARCHAR2(50 BYTE),
  registration_mask VARCHAR2(100 BYTE),
  simple_registration_mask VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  unit_of_measure_code VARCHAR2(25 BYTE),
  uuid VARCHAR2(36 BYTE),
  aud_authority_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;