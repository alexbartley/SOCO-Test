CREATE TABLE sbxtax2.a_authorities (
  authority_id NUMBER(10),
  product_group_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  uuid VARCHAR2(36 BYTE),
  invoice_description VARCHAR2(100 BYTE),
  description VARCHAR2(100 BYTE),
  merchant_id NUMBER(10),
  region_code VARCHAR2(50 BYTE),
  registration_mask VARCHAR2(100 BYTE),
  simple_registration_mask VARCHAR2(100 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  admin_zone_level_id NUMBER(10),
  effective_zone_level_id NUMBER(10),
  authority_type_id NUMBER(10),
  location_code VARCHAR2(50 BYTE),
  distance_sales_threshold NUMBER(31,5),
  is_template VARCHAR2(1 BYTE),
  is_custom_authority VARCHAR2(1 BYTE),
  erp_tax_code VARCHAR2(200 BYTE),
  content_type VARCHAR2(50 BYTE),
  unit_of_measure_code VARCHAR2(25 BYTE),
  official_name VARCHAR2(100 BYTE),
  authority_category VARCHAR2(100 BYTE),
  product_group_id_o NUMBER(10),
  name_o VARCHAR2(100 BYTE),
  uuid_o VARCHAR2(36 BYTE),
  invoice_description_o VARCHAR2(100 BYTE),
  description_o VARCHAR2(100 BYTE),
  merchant_id_o NUMBER(10),
  region_code_o VARCHAR2(50 BYTE),
  registration_mask_o VARCHAR2(100 BYTE),
  simple_registration_mask_o VARCHAR2(100 BYTE),
  created_by_o NUMBER(10),
  creation_date_o DATE,
  last_updated_by_o NUMBER(10),
  last_update_date_o DATE,
  admin_zone_level_id_o NUMBER(10),
  effective_zone_level_id_o NUMBER(10),
  authority_type_id_o NUMBER(10),
  location_code_o VARCHAR2(50 BYTE),
  distance_sales_threshold_o NUMBER(31,5),
  is_template_o VARCHAR2(1 BYTE),
  is_custom_authority_o VARCHAR2(1 BYTE),
  erp_tax_code_o VARCHAR2(200 BYTE),
  content_type_o VARCHAR2(50 BYTE),
  unit_of_measure_code_o VARCHAR2(25 BYTE),
  official_name_o VARCHAR2(100 BYTE),
  authority_category_o VARCHAR2(100 BYTE),
  authority_id_o NUMBER(10),
  change_type VARCHAR2(100 BYTE) NOT NULL,
  change_version VARCHAR2(50 BYTE),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;