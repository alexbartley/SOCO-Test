CREATE TABLE sbxtax4.tb_authorities (
  authority_id NUMBER NOT NULL,
  product_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  invoice_description VARCHAR2(100 BYTE),
  description VARCHAR2(100 BYTE),
  merchant_id NUMBER NOT NULL,
  region_code VARCHAR2(50 BYTE),
  registration_mask VARCHAR2(100 BYTE),
  simple_registration_mask VARCHAR2(100 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  admin_zone_level_id NUMBER,
  effective_zone_level_id NUMBER,
  authority_type_id NUMBER NOT NULL,
  location_code VARCHAR2(50 BYTE),
  distance_sales_threshold NUMBER(31,5),
  is_template VARCHAR2(1 BYTE),
  erp_tax_code VARCHAR2(200 BYTE),
  uuid VARCHAR2(36 BYTE) DEFAULT '.' NOT NULL,
  is_custom_authority VARCHAR2(1 BYTE) DEFAULT 'N' NOT NULL,
  content_type VARCHAR2(50 BYTE) DEFAULT '.' NOT NULL,
  unit_of_measure_code VARCHAR2(25 BYTE),
  official_name VARCHAR2(100 BYTE),
  authority_category VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;