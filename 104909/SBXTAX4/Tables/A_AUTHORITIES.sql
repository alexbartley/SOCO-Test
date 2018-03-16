CREATE TABLE sbxtax4.a_authorities (
  authority_id NUMBER,
  product_group_id NUMBER,
  "NAME" VARCHAR2(100 CHAR),
  uuid VARCHAR2(36 CHAR),
  invoice_description VARCHAR2(100 CHAR),
  description VARCHAR2(100 CHAR),
  merchant_id NUMBER,
  region_code VARCHAR2(50 CHAR),
  registration_mask VARCHAR2(100 CHAR),
  simple_registration_mask VARCHAR2(100 CHAR),
  created_by NUMBER,
  creation_date DATE,
  last_updated_by NUMBER,
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP,
  admin_zone_level_id NUMBER,
  effective_zone_level_id NUMBER,
  authority_type_id NUMBER,
  location_code VARCHAR2(50 CHAR),
  distance_sales_threshold NUMBER(31,5),
  is_template VARCHAR2(1 CHAR),
  is_custom_authority VARCHAR2(1 CHAR),
  erp_tax_code VARCHAR2(200 CHAR),
  content_type VARCHAR2(50 CHAR),
  unit_of_measure_code VARCHAR2(25 CHAR),
  official_name VARCHAR2(100 CHAR),
  authority_category VARCHAR2(100 CHAR),
  product_group_id_o NUMBER,
  name_o VARCHAR2(100 CHAR),
  uuid_o VARCHAR2(36 CHAR),
  invoice_description_o VARCHAR2(100 CHAR),
  description_o VARCHAR2(100 CHAR),
  merchant_id_o NUMBER,
  region_code_o VARCHAR2(50 CHAR),
  registration_mask_o VARCHAR2(100 CHAR),
  simple_registration_mask_o VARCHAR2(100 CHAR),
  created_by_o NUMBER,
  creation_date_o DATE,
  last_updated_by_o NUMBER,
  last_update_date_o DATE,
  synchronization_timestamp_o TIMESTAMP,
  admin_zone_level_id_o NUMBER,
  effective_zone_level_id_o NUMBER,
  authority_type_id_o NUMBER,
  location_code_o VARCHAR2(50 CHAR),
  distance_sales_threshold_o NUMBER(31,5),
  is_template_o VARCHAR2(1 CHAR),
  is_custom_authority_o VARCHAR2(1 CHAR),
  erp_tax_code_o VARCHAR2(200 CHAR),
  content_type_o VARCHAR2(50 CHAR),
  unit_of_measure_code_o VARCHAR2(25 CHAR),
  official_name_o VARCHAR2(100 CHAR),
  authority_category_o VARCHAR2(100 CHAR),
  authority_id_o NUMBER,
  change_type VARCHAR2(100 CHAR) NOT NULL,
  change_version VARCHAR2(50 CHAR),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;