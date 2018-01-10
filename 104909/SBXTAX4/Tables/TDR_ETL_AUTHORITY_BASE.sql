CREATE TABLE sbxtax4.tdr_etl_authority_base (
  nkid NUMBER NOT NULL,
  authority_uuid VARCHAR2(36 CHAR),
  description VARCHAR2(1000 CHAR),
  effective_zone_level VARCHAR2(100 CHAR) NOT NULL,
  authority_category VARCHAR2(250 CHAR),
  location_code VARCHAR2(250 CHAR),
  authority_type VARCHAR2(100 CHAR),
  administrator_name VARCHAR2(100 CHAR),
  "NAME" VARCHAR2(100 CHAR),
  administrator_type VARCHAR2(100 CHAR),
  extract_id NUMBER,
  default_product_group VARCHAR2(400 CHAR),
  official_name VARCHAR2(400 CHAR),
  erp_tax_code VARCHAR2(10 CHAR),
  rid NUMBER,
  registration_mask VARCHAR2(100 CHAR)
) 
TABLESPACE ositax;