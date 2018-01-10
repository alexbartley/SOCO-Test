CREATE TABLE sbxtax.ht_scenario_lines (
  allocation_group_name VARCHAR2(100 BYTE),
  allocation_group_owner VARCHAR2(100 BYTE),
  allocation_name VARCHAR2(100 BYTE),
  basis_percent NUMBER(31,10),
  bp_city VARCHAR2(50 BYTE),
  bp_company_branch_id VARCHAR2(25 BYTE),
  bp_country VARCHAR2(3 BYTE),
  bp_county VARCHAR2(50 BYTE),
  bp_district VARCHAR2(50 BYTE),
  bp_geocode VARCHAR2(50 BYTE),
  bp_is_bonded VARCHAR2(1 BYTE),
  bp_location_tax_category VARCHAR2(100 BYTE),
  bp_postcode VARCHAR2(50 BYTE),
  bp_province VARCHAR2(50 BYTE),
  bp_state VARCHAR2(50 BYTE),
  bt_city VARCHAR2(50 BYTE),
  bt_company_branch_id VARCHAR2(25 BYTE),
  bt_country VARCHAR2(3 BYTE),
  bt_county VARCHAR2(50 BYTE),
  bt_district VARCHAR2(50 BYTE),
  bt_geocode VARCHAR2(50 BYTE),
  bt_is_bonded VARCHAR2(1 BYTE),
  bt_location_tax_category VARCHAR2(100 BYTE),
  bt_postcode VARCHAR2(50 BYTE),
  bt_province VARCHAR2(50 BYTE),
  bt_state VARCHAR2(50 BYTE),
  commodity_code VARCHAR2(50 BYTE),
  country_of_origin VARCHAR2(100 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  customer_name VARCHAR2(100 BYTE),
  customer_number VARCHAR2(100 BYTE),
  delivery_terms VARCHAR2(100 BYTE),
  dept_of_consign VARCHAR2(100 BYTE),
  description VARCHAR2(200 BYTE),
  discount_amount NUMBER(31,5),
  discount_amount_func NUMBER(31,5),
  est_buyer_bill_to VARCHAR2(1 BYTE),
  est_buyer_buyer_primary VARCHAR2(1 BYTE),
  est_buyer_middleman VARCHAR2(1 BYTE),
  est_buyer_order_acceptance VARCHAR2(1 BYTE),
  est_buyer_order_origin VARCHAR2(1 BYTE),
  est_buyer_seller_primary VARCHAR2(1 BYTE),
  est_buyer_ship_from VARCHAR2(1 BYTE),
  est_buyer_ship_to VARCHAR2(1 BYTE),
  est_buyer_supply VARCHAR2(1 BYTE),
  est_middleman_bill_to VARCHAR2(1 BYTE),
  est_middleman_buyer_primary VARCHAR2(1 BYTE),
  est_middleman_middleman VARCHAR2(1 BYTE),
  est_middleman_order_acceptance VARCHAR2(1 BYTE),
  est_middleman_order_origin VARCHAR2(1 BYTE),
  est_middleman_seller_primary VARCHAR2(1 BYTE),
  est_middleman_ship_from VARCHAR2(1 BYTE),
  est_middleman_ship_to VARCHAR2(1 BYTE),
  est_middleman_supply VARCHAR2(1 BYTE),
  est_seller_bill_to VARCHAR2(1 BYTE),
  est_seller_buyer_primary VARCHAR2(1 BYTE),
  est_seller_middleman VARCHAR2(1 BYTE),
  est_seller_order_acceptance VARCHAR2(1 BYTE),
  est_seller_order_origin VARCHAR2(1 BYTE),
  est_seller_seller_primary VARCHAR2(1 BYTE),
  est_seller_ship_from VARCHAR2(1 BYTE),
  est_seller_ship_to VARCHAR2(1 BYTE),
  est_seller_supply VARCHAR2(1 BYTE),
  exempt_amount_city NUMBER(31,5),
  exempt_amount_city_func NUMBER(31,5),
  exempt_amount_country NUMBER(31,5),
  exempt_amount_country_func NUMBER(31,5),
  exempt_amount_county NUMBER(31,5),
  exempt_amount_county_func NUMBER(31,5),
  exempt_amount_district NUMBER(31,5),
  exempt_amount_district_func NUMBER(31,5),
  exempt_amount_geocode NUMBER(31,5),
  exempt_amount_geocode_func NUMBER(31,5),
  exempt_amount_postcode NUMBER(31,5),
  exempt_amount_postcode_func NUMBER(31,5),
  exempt_amount_province NUMBER(31,5),
  exempt_amount_province_func NUMBER(31,5),
  exempt_amount_state NUMBER(31,5),
  exempt_amount_state_func NUMBER(31,5),
  exempt_certificate_city VARCHAR2(100 BYTE),
  exempt_certificate_country VARCHAR2(100 BYTE),
  exempt_certificate_county VARCHAR2(100 BYTE),
  exempt_certificate_district VARCHAR2(100 BYTE),
  exempt_certificate_geocode VARCHAR2(100 BYTE),
  exempt_certificate_postcode VARCHAR2(100 BYTE),
  exempt_certificate_province VARCHAR2(100 BYTE),
  exempt_certificate_state VARCHAR2(100 BYTE),
  exempt_reason_city VARCHAR2(20 BYTE),
  exempt_reason_country VARCHAR2(20 BYTE),
  exempt_reason_county VARCHAR2(20 BYTE),
  exempt_reason_district VARCHAR2(20 BYTE),
  exempt_reason_geocode VARCHAR2(20 BYTE),
  exempt_reason_postcode VARCHAR2(20 BYTE),
  exempt_reason_province VARCHAR2(20 BYTE),
  exempt_reason_state VARCHAR2(20 BYTE),
  fully_inclusive VARCHAR2(1 BYTE),
  gross_amount NUMBER(31,5),
  gross_amount_func NUMBER(31,5),
  header_scenario_id NUMBER(10),
  input_recovery_amount NUMBER(31,5),
  input_recovery_amount_func NUMBER(31,5),
  input_recovery_percent NUMBER(31,10),
  input_recovery_type VARCHAR2(50 BYTE),
  is_allocatable VARCHAR2(1 BYTE),
  is_business_supply VARCHAR2(1 BYTE),
  is_exempt_all VARCHAR2(1 BYTE),
  is_exempt_city VARCHAR2(1 BYTE),
  is_exempt_country VARCHAR2(1 BYTE),
  is_exempt_county VARCHAR2(1 BYTE),
  is_exempt_district VARCHAR2(1 BYTE),
  is_exempt_geocode VARCHAR2(1 BYTE),
  is_exempt_postcode VARCHAR2(1 BYTE),
  is_exempt_province VARCHAR2(1 BYTE),
  is_exempt_state VARCHAR2(1 BYTE),
  is_manufacturing VARCHAR2(1 BYTE),
  is_no_tax_all VARCHAR2(1 BYTE),
  is_no_tax_city VARCHAR2(1 BYTE),
  is_no_tax_country VARCHAR2(1 BYTE),
  is_no_tax_county VARCHAR2(1 BYTE),
  is_no_tax_district VARCHAR2(1 BYTE),
  is_no_tax_geocode VARCHAR2(1 BYTE),
  is_no_tax_postcode VARCHAR2(1 BYTE),
  is_no_tax_province VARCHAR2(1 BYTE),
  is_no_tax_state VARCHAR2(1 BYTE),
  is_simplification VARCHAR2(1 BYTE),
  item_value NUMBER(31,5),
  item_value_func NUMBER(31,5),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  line_number NUMBER(10),
  location_bill_to VARCHAR2(30 BYTE),
  location_middleman VARCHAR2(30 BYTE),
  location_order_acceptance VARCHAR2(30 BYTE),
  location_order_origin VARCHAR2(30 BYTE),
  location_set VARCHAR2(60 BYTE),
  location_ship_from VARCHAR2(30 BYTE),
  location_ship_to VARCHAR2(30 BYTE),
  location_supply VARCHAR2(30 BYTE),
  mass NUMBER(10),
  middleman_markup_amount NUMBER(31,5),
  middleman_markup_amount_func NUMBER(31,5),
  middleman_markup_rate NUMBER(31,10),
  mm_city VARCHAR2(50 BYTE),
  mm_company_branch_id VARCHAR2(25 BYTE),
  mm_country VARCHAR2(3 BYTE),
  mm_county VARCHAR2(50 BYTE),
  mm_district VARCHAR2(50 BYTE),
  mm_geocode VARCHAR2(50 BYTE),
  mm_is_bonded VARCHAR2(1 BYTE),
  mm_location_tax_category VARCHAR2(100 BYTE),
  mm_postcode VARCHAR2(50 BYTE),
  mm_province VARCHAR2(50 BYTE),
  mm_state VARCHAR2(50 BYTE),
  mode_of_transport VARCHAR2(50 BYTE),
  movement_date DATE,
  movement_type VARCHAR2(100 BYTE),
  oa_city VARCHAR2(50 BYTE),
  oa_company_branch_id VARCHAR2(25 BYTE),
  oa_country VARCHAR2(3 BYTE),
  oa_county VARCHAR2(50 BYTE),
  oa_district VARCHAR2(50 BYTE),
  oa_geocode VARCHAR2(50 BYTE),
  oa_is_bonded VARCHAR2(1 BYTE),
  oa_location_tax_category VARCHAR2(100 BYTE),
  oa_postcode VARCHAR2(50 BYTE),
  oa_province VARCHAR2(50 BYTE),
  oa_state VARCHAR2(50 BYTE),
  oo_city VARCHAR2(50 BYTE),
  oo_company_branch_id VARCHAR2(25 BYTE),
  oo_country VARCHAR2(3 BYTE),
  oo_county VARCHAR2(50 BYTE),
  oo_district VARCHAR2(50 BYTE),
  oo_geocode VARCHAR2(50 BYTE),
  oo_is_bonded VARCHAR2(1 BYTE),
  oo_location_tax_category VARCHAR2(100 BYTE),
  oo_postcode VARCHAR2(50 BYTE),
  oo_province VARCHAR2(50 BYTE),
  oo_state VARCHAR2(50 BYTE),
  original_invoice_date DATE,
  override_amount_city NUMBER(31,5),
  override_amount_city_func NUMBER(31,5),
  override_amount_country NUMBER(31,5),
  override_amount_country_func NUMBER(31,5),
  override_amount_county NUMBER(31,5),
  override_amount_county_func NUMBER(31,5),
  override_amount_district NUMBER(31,5),
  override_amount_district_func NUMBER(31,5),
  override_amount_geocode NUMBER(31,5),
  override_amount_geocode_func NUMBER(31,5),
  override_amount_postcode NUMBER(31,5),
  override_amount_postcode_func NUMBER(31,5),
  override_amount_province NUMBER(31,5),
  override_amount_province_func NUMBER(31,5),
  override_amount_state NUMBER(31,5),
  override_amount_state_func NUMBER(31,5),
  override_rate_city NUMBER(31,10),
  override_rate_country NUMBER(31,10),
  override_rate_county NUMBER(31,10),
  override_rate_district NUMBER(31,10),
  override_rate_geocode NUMBER(31,10),
  override_rate_postcode NUMBER(31,10),
  override_rate_province NUMBER(31,10),
  override_rate_state NUMBER(31,10),
  part_number VARCHAR2(20 BYTE),
  point_of_title_transfer VARCHAR2(3 BYTE),
  port_of_entry VARCHAR2(100 BYTE),
  port_of_loading VARCHAR2(5 BYTE),
  product_code VARCHAR2(100 BYTE),
  quantity NUMBER(31,10),
  quantity_uom_code VARCHAR2(25 BYTE),
  regime VARCHAR2(100 BYTE),
  related_line_number NUMBER(10),
  scenario_line_id NUMBER(10),
  sf_city VARCHAR2(50 BYTE),
  sf_company_branch_id VARCHAR2(25 BYTE),
  sf_country VARCHAR2(3 BYTE),
  sf_county VARCHAR2(50 BYTE),
  sf_district VARCHAR2(50 BYTE),
  sf_geocode VARCHAR2(50 BYTE),
  sf_is_bonded VARCHAR2(1 BYTE),
  sf_location_tax_category VARCHAR2(100 BYTE),
  sf_postcode VARCHAR2(50 BYTE),
  sf_province VARCHAR2(50 BYTE),
  sf_state VARCHAR2(50 BYTE),
  sp_city VARCHAR2(50 BYTE),
  sp_company_branch_id VARCHAR2(25 BYTE),
  sp_country VARCHAR2(3 BYTE),
  sp_county VARCHAR2(50 BYTE),
  sp_district VARCHAR2(50 BYTE),
  sp_geocode VARCHAR2(50 BYTE),
  sp_is_bonded VARCHAR2(1 BYTE),
  sp_location_tax_category VARCHAR2(100 BYTE),
  sp_postcode VARCHAR2(50 BYTE),
  sp_province VARCHAR2(50 BYTE),
  sp_state VARCHAR2(50 BYTE),
  st_city VARCHAR2(50 BYTE),
  st_company_branch_id VARCHAR2(25 BYTE),
  st_country VARCHAR2(3 BYTE),
  st_county VARCHAR2(50 BYTE),
  st_district VARCHAR2(50 BYTE),
  st_geocode VARCHAR2(50 BYTE),
  st_is_bonded VARCHAR2(1 BYTE),
  st_location_tax_category VARCHAR2(100 BYTE),
  st_postcode VARCHAR2(50 BYTE),
  st_province VARCHAR2(50 BYTE),
  st_state VARCHAR2(50 BYTE),
  supplementary_unit VARCHAR2(5 BYTE),
  supply_exempt_percent_city NUMBER(31,10),
  supply_exempt_percent_country NUMBER(31,10),
  supply_exempt_percent_county NUMBER(31,10),
  supply_exempt_percent_district NUMBER(31,10),
  supply_exempt_percent_geocode NUMBER(31,10),
  supply_exempt_percent_postcode NUMBER(31,10),
  supply_exempt_percent_province NUMBER(31,10),
  supply_exempt_percent_state NUMBER(31,10),
  su_city VARCHAR2(50 BYTE),
  su_company_branch_id VARCHAR2(25 BYTE),
  su_country VARCHAR2(3 BYTE),
  su_county VARCHAR2(50 BYTE),
  su_district VARCHAR2(50 BYTE),
  su_geocode VARCHAR2(50 BYTE),
  su_is_bonded VARCHAR2(1 BYTE),
  su_location_tax_category VARCHAR2(100 BYTE),
  su_postcode VARCHAR2(50 BYTE),
  su_province VARCHAR2(50 BYTE),
  su_state VARCHAR2(50 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  tax_amount NUMBER(31,5),
  tax_amount_func NUMBER(31,5),
  tax_code VARCHAR2(50 BYTE),
  tax_plus_gross NUMBER(31,5),
  tax_plus_gross_func NUMBER(10),
  tax_type_all VARCHAR2(20 BYTE),
  tax_type_city VARCHAR2(20 BYTE),
  tax_type_country VARCHAR2(20 BYTE),
  tax_type_county VARCHAR2(20 BYTE),
  tax_type_district VARCHAR2(20 BYTE),
  tax_type_geocode VARCHAR2(20 BYTE),
  tax_type_postcode VARCHAR2(20 BYTE),
  tax_type_province VARCHAR2(20 BYTE),
  tax_type_state VARCHAR2(20 BYTE),
  title_transfer_location VARCHAR2(100 BYTE),
  transaction_type VARCHAR2(2 BYTE),
  unique_line_number VARCHAR2(100 BYTE),
  unit_of_measure_code VARCHAR2(25 BYTE),
  user_element_attribute1 VARCHAR2(200 BYTE),
  user_element_attribute10 VARCHAR2(200 BYTE),
  user_element_attribute11 VARCHAR2(200 BYTE),
  user_element_attribute12 VARCHAR2(200 BYTE),
  user_element_attribute13 VARCHAR2(200 BYTE),
  user_element_attribute14 VARCHAR2(200 BYTE),
  user_element_attribute15 VARCHAR2(200 BYTE),
  user_element_attribute16 VARCHAR2(200 BYTE),
  user_element_attribute17 VARCHAR2(200 BYTE),
  user_element_attribute18 VARCHAR2(200 BYTE),
  user_element_attribute19 VARCHAR2(200 BYTE),
  user_element_attribute2 VARCHAR2(200 BYTE),
  user_element_attribute20 VARCHAR2(200 BYTE),
  user_element_attribute21 VARCHAR2(200 BYTE),
  user_element_attribute22 VARCHAR2(200 BYTE),
  user_element_attribute23 VARCHAR2(200 BYTE),
  user_element_attribute24 VARCHAR2(200 BYTE),
  user_element_attribute25 VARCHAR2(200 BYTE),
  user_element_attribute26 VARCHAR2(200 BYTE),
  user_element_attribute27 VARCHAR2(200 BYTE),
  user_element_attribute28 VARCHAR2(200 BYTE),
  user_element_attribute29 VARCHAR2(200 BYTE),
  user_element_attribute3 VARCHAR2(200 BYTE),
  user_element_attribute30 VARCHAR2(200 BYTE),
  user_element_attribute31 VARCHAR2(200 BYTE),
  user_element_attribute32 VARCHAR2(200 BYTE),
  user_element_attribute33 VARCHAR2(200 BYTE),
  user_element_attribute34 VARCHAR2(200 BYTE),
  user_element_attribute35 VARCHAR2(200 BYTE),
  user_element_attribute36 VARCHAR2(200 BYTE),
  user_element_attribute37 VARCHAR2(200 BYTE),
  user_element_attribute38 VARCHAR2(200 BYTE),
  user_element_attribute39 VARCHAR2(200 BYTE),
  user_element_attribute4 VARCHAR2(200 BYTE),
  user_element_attribute40 VARCHAR2(200 BYTE),
  user_element_attribute41 VARCHAR2(200 BYTE),
  user_element_attribute42 VARCHAR2(200 BYTE),
  user_element_attribute43 VARCHAR2(200 BYTE),
  user_element_attribute44 VARCHAR2(200 BYTE),
  user_element_attribute45 VARCHAR2(200 BYTE),
  user_element_attribute46 VARCHAR2(200 BYTE),
  user_element_attribute47 VARCHAR2(200 BYTE),
  user_element_attribute48 VARCHAR2(200 BYTE),
  user_element_attribute49 VARCHAR2(200 BYTE),
  user_element_attribute5 VARCHAR2(200 BYTE),
  user_element_attribute50 VARCHAR2(200 BYTE),
  user_element_attribute6 VARCHAR2(200 BYTE),
  user_element_attribute7 VARCHAR2(200 BYTE),
  user_element_attribute8 VARCHAR2(200 BYTE),
  user_element_attribute9 VARCHAR2(200 BYTE),
  vat_group_registration_number VARCHAR2(50 BYTE),
  vendor_name VARCHAR2(100 BYTE),
  vendor_number VARCHAR2(100 BYTE),
  vendor_tax NUMBER(10),
  vendor_tax_func NUMBER(10),
  aud_scenario_line_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;