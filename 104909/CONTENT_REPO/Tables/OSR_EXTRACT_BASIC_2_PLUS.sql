CREATE TABLE content_repo.osr_extract_basic_2_plus (
  zip_code VARCHAR2(5 CHAR),
  state_code VARCHAR2(2 CHAR),
  county_name VARCHAR2(65 CHAR),
  city_name VARCHAR2(65 CHAR),
  state_sales_tax VARCHAR2(35 CHAR),
  state_use_tax VARCHAR2(35 CHAR),
  county_sales_tax VARCHAR2(35 CHAR),
  county_use_tax VARCHAR2(35 CHAR),
  city_sales_tax VARCHAR2(35 CHAR),
  city_use_tax VARCHAR2(35 CHAR),
  total_sales_tax VARCHAR2(35 CHAR),
  total_use_tax VARCHAR2(35 CHAR),
  tax_shipping_alone VARCHAR2(35 CHAR),
  tax_shipping_and_handling VARCHAR2(35 CHAR),
  fips_state VARCHAR2(2 CHAR),
  fips_county VARCHAR2(3 CHAR),
  fips_city VARCHAR2(5 CHAR),
  geocode VARCHAR2(200 CHAR),
  state_effective_date VARCHAR2(15 CHAR),
  county_effective_date VARCHAR2(15 CHAR),
  city_effective_date VARCHAR2(15 CHAR)
) 
TABLESPACE content_repo;