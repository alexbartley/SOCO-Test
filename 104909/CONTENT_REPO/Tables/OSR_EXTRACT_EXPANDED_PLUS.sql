CREATE TABLE content_repo.osr_extract_expanded_plus (
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
  mta_sales_tax VARCHAR2(35 CHAR),
  mta_use_tax VARCHAR2(35 CHAR),
  spd_sales_tax VARCHAR2(35 CHAR),
  spd_use_tax VARCHAR2(35 CHAR),
  other1_sales_tax VARCHAR2(35 CHAR),
  other1_use_tax VARCHAR2(35 CHAR),
  other2_sales_tax VARCHAR2(35 CHAR),
  other2_use_tax VARCHAR2(35 CHAR),
  other3_sales_tax VARCHAR2(35 CHAR),
  other3_use_tax VARCHAR2(35 CHAR),
  other4_sales_tax VARCHAR2(35 CHAR),
  other4_use_tax VARCHAR2(35 CHAR),
  total_sales_tax VARCHAR2(35 CHAR),
  total_use_tax VARCHAR2(35 CHAR),
  county_number VARCHAR2(35 CHAR),
  city_number VARCHAR2(35 CHAR),
  mta_name VARCHAR2(50 CHAR),
  mta_number VARCHAR2(35 CHAR),
  spd_name VARCHAR2(200 CHAR),
  spd_number VARCHAR2(35 CHAR),
  other1_name VARCHAR2(200 CHAR),
  other1_number VARCHAR2(35 CHAR),
  other2_name VARCHAR2(200 CHAR),
  other2_number VARCHAR2(35 CHAR),
  other3_name VARCHAR2(200 CHAR),
  other3_number VARCHAR2(35 CHAR),
  other4_name VARCHAR2(200 CHAR),
  other4_number VARCHAR2(35 CHAR),
  tax_shipping_alone VARCHAR2(35 CHAR),
  tax_shipping_and_handling VARCHAR2(35 CHAR),
  fips_state VARCHAR2(2 CHAR),
  fips_county VARCHAR2(3 CHAR),
  fips_city VARCHAR2(5 CHAR),
  geocode VARCHAR2(200 CHAR),
  mta_geocode VARCHAR2(50 CHAR),
  spd_geocode VARCHAR2(50 CHAR),
  other1_geocode VARCHAR2(50 CHAR),
  other2_geocode VARCHAR2(50 CHAR),
  other3_geocode VARCHAR2(50 CHAR),
  other4_geocode VARCHAR2(50 CHAR),
  geocode_long VARCHAR2(500 CHAR),
  state_effective_date VARCHAR2(15 CHAR),
  county_effective_date VARCHAR2(15 CHAR),
  city_effective_date VARCHAR2(15 CHAR),
  mta_effective_date VARCHAR2(15 CHAR),
  spd_effective_date VARCHAR2(15 CHAR),
  other1_effective_date VARCHAR2(15 CHAR),
  other2_effective_date VARCHAR2(15 CHAR),
  other3_effective_date VARCHAR2(15 CHAR),
  other4_effective_date VARCHAR2(15 CHAR),
  county_tax_collected_by VARCHAR2(250 CHAR),
  city_tax_collected_by VARCHAR2(250 CHAR),
  state_taxable_max VARCHAR2(20 CHAR),
  state_tax_over_max VARCHAR2(20 CHAR),
  county_taxable_max VARCHAR2(20 CHAR),
  county_tax_over_max VARCHAR2(20 CHAR),
  city_taxable_max VARCHAR2(20 CHAR),
  city_tax_over_max VARCHAR2(20 CHAR),
  sales_tax_holiday VARCHAR2(1 CHAR),
  sales_tax_holiday_dates VARCHAR2(50 CHAR),
  sales_tax_holiday_items VARCHAR2(250 CHAR)
) 
TABLESPACE content_repo;