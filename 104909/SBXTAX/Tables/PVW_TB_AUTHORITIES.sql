CREATE TABLE sbxtax.pvw_tb_authorities (
  jurisdiction_nkid NUMBER,
  uuid VARCHAR2(36 CHAR),
  authority_type_id NUMBER,
  location_code VARCHAR2(100 CHAR),
  official_name VARCHAR2(100 CHAR),
  authority_category VARCHAR2(100 CHAR),
  "NAME" VARCHAR2(100 CHAR),
  description VARCHAR2(250 CHAR),
  admin_zone_level_id NUMBER,
  effective_zone_level_id NUMBER,
  content_type VARCHAR2(50 CHAR),
  product_group_id NUMBER,
  registration_mask VARCHAR2(100 CHAR),
  erp_tax_code VARCHAR2(100 CHAR)
) 
TABLESPACE ositax;