CREATE TABLE sbxtax4.tdr_etl_tb_authorities (
  authority_type VARCHAR2(100 CHAR),
  location_code VARCHAR2(100 CHAR),
  official_name VARCHAR2(100 CHAR),
  authority_category VARCHAR2(100 CHAR),
  "NAME" VARCHAR2(100 CHAR),
  description VARCHAR2(250 CHAR),
  admin_zone_level VARCHAR2(50 CHAR),
  effective_zone_level VARCHAR2(50 CHAR),
  authority_uuid VARCHAR2(36 CHAR),
  nkid NUMBER,
  attr_default_product_group VARCHAR2(400 CHAR),
  attr_official_name VARCHAR2(400 CHAR),
  rid NUMBER,
  content_type VARCHAR2(50 CHAR),
  registration_mask VARCHAR2(100 CHAR),
  erp_tax_code VARCHAR2(100 CHAR)
) 
TABLESPACE ositax;