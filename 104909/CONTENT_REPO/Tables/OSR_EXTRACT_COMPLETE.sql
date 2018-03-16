CREATE TABLE content_repo.osr_extract_complete (
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
  tax_shipping_and_handling VARCHAR2(35 CHAR)
) 
TABLESPACE content_repo;