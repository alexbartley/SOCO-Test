CREATE TABLE sbxtax3.ht_merchants (
  "ACTIVE" VARCHAR2(1 BYTE),
  allocation_group_name VARCHAR2(100 BYTE),
  allocation_group_owner_id NUMBER(10),
  audit_message_threshold NUMBER(10),
  b2b_create_merchant VARCHAR2(1 BYTE),
  b2b_flag VARCHAR2(1 BYTE),
  b2b_parent_merchant_id NUMBER(10),
  b2b_use_parent_prefs VARCHAR2(1 BYTE),
  content_comment VARCHAR2(50 BYTE),
  content_type VARCHAR2(100 BYTE),
  content_version VARCHAR2(20 BYTE),
  created_by NUMBER(10),
  create_auto_certs VARCHAR2(1 BYTE),
  create_customers VARCHAR2(1 BYTE),
  creation_date DATE,
  customer_group_id NUMBER(10),
  days_valid NUMBER(10),
  default_cert_status VARCHAR2(1 BYTE),
  def_intl_exempt_reason_id NUMBER(10),
  def_us_exempt_reason_id NUMBER(10),
  exempt_temp_cert_trans VARCHAR2(1 BYTE),
  external_token VARCHAR2(36 BYTE),
  filter_group_name VARCHAR2(100 BYTE),
  filter_group_owner_id NUMBER(10),
  intl_content_provider_id NUMBER(10),
  intl_custom_data_provider_id NUMBER(10),
  intl_established_merchant_id NUMBER(10),
  intl_exchange_rate_merchant_id NUMBER(10),
  intl_product_group_id NUMBER(10),
  inv_attribute_10_name VARCHAR2(200 BYTE),
  inv_attribute_11_name VARCHAR2(200 BYTE),
  inv_attribute_12_name VARCHAR2(200 BYTE),
  inv_attribute_13_name VARCHAR2(200 BYTE),
  inv_attribute_14_name VARCHAR2(200 BYTE),
  inv_attribute_15_name VARCHAR2(200 BYTE),
  inv_attribute_16_name VARCHAR2(200 BYTE),
  inv_attribute_17_name VARCHAR2(200 BYTE),
  inv_attribute_18_name VARCHAR2(200 BYTE),
  inv_attribute_19_name VARCHAR2(200 BYTE),
  inv_attribute_1_name VARCHAR2(200 BYTE),
  inv_attribute_20_name VARCHAR2(200 BYTE),
  inv_attribute_21_name VARCHAR2(200 BYTE),
  inv_attribute_22_name VARCHAR2(200 BYTE),
  inv_attribute_23_name VARCHAR2(200 BYTE),
  inv_attribute_24_name VARCHAR2(200 BYTE),
  inv_attribute_25_name VARCHAR2(200 BYTE),
  inv_attribute_26_name VARCHAR2(200 BYTE),
  inv_attribute_27_name VARCHAR2(200 BYTE),
  inv_attribute_28_name VARCHAR2(200 BYTE),
  inv_attribute_29_name VARCHAR2(200 BYTE),
  inv_attribute_2_name VARCHAR2(200 BYTE),
  inv_attribute_30_name VARCHAR2(200 BYTE),
  inv_attribute_31_name VARCHAR2(200 BYTE),
  inv_attribute_32_name VARCHAR2(200 BYTE),
  inv_attribute_33_name VARCHAR2(200 BYTE),
  inv_attribute_34_name VARCHAR2(200 BYTE),
  inv_attribute_35_name VARCHAR2(200 BYTE),
  inv_attribute_36_name VARCHAR2(200 BYTE),
  inv_attribute_37_name VARCHAR2(200 BYTE),
  inv_attribute_38_name VARCHAR2(200 BYTE),
  inv_attribute_39_name VARCHAR2(200 BYTE),
  inv_attribute_3_name VARCHAR2(200 BYTE),
  inv_attribute_40_name VARCHAR2(200 BYTE),
  inv_attribute_41_name VARCHAR2(200 BYTE),
  inv_attribute_42_name VARCHAR2(200 BYTE),
  inv_attribute_43_name VARCHAR2(200 BYTE),
  inv_attribute_44_name VARCHAR2(200 BYTE),
  inv_attribute_45_name VARCHAR2(200 BYTE),
  inv_attribute_46_name VARCHAR2(200 BYTE),
  inv_attribute_47_name VARCHAR2(200 BYTE),
  inv_attribute_48_name VARCHAR2(200 BYTE),
  inv_attribute_49_name VARCHAR2(200 BYTE),
  inv_attribute_4_name VARCHAR2(200 BYTE),
  inv_attribute_50_name VARCHAR2(200 BYTE),
  inv_attribute_5_name VARCHAR2(200 BYTE),
  inv_attribute_6_name VARCHAR2(200 BYTE),
  inv_attribute_7_name VARCHAR2(200 BYTE),
  inv_attribute_8_name VARCHAR2(200 BYTE),
  inv_attribute_9_name VARCHAR2(200 BYTE),
  is_auditing_messages VARCHAR2(1 BYTE),
  is_content_provider VARCHAR2(1 BYTE),
  is_using_reporting_periods VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  legal_entity_name VARCHAR2(200 BYTE),
  line_attribute_10_name VARCHAR2(200 BYTE),
  line_attribute_11_name VARCHAR2(200 BYTE),
  line_attribute_12_name VARCHAR2(200 BYTE),
  line_attribute_13_name VARCHAR2(200 BYTE),
  line_attribute_14_name VARCHAR2(200 BYTE),
  line_attribute_15_name VARCHAR2(200 BYTE),
  line_attribute_16_name VARCHAR2(200 BYTE),
  line_attribute_17_name VARCHAR2(200 BYTE),
  line_attribute_18_name VARCHAR2(200 BYTE),
  line_attribute_19_name VARCHAR2(200 BYTE),
  line_attribute_1_name VARCHAR2(200 BYTE),
  line_attribute_20_name VARCHAR2(200 BYTE),
  line_attribute_21_name VARCHAR2(200 BYTE),
  line_attribute_22_name VARCHAR2(200 BYTE),
  line_attribute_23_name VARCHAR2(200 BYTE),
  line_attribute_24_name VARCHAR2(200 BYTE),
  line_attribute_25_name VARCHAR2(200 BYTE),
  line_attribute_26_name VARCHAR2(200 BYTE),
  line_attribute_27_name VARCHAR2(200 BYTE),
  line_attribute_28_name VARCHAR2(200 BYTE),
  line_attribute_29_name VARCHAR2(200 BYTE),
  line_attribute_2_name VARCHAR2(200 BYTE),
  line_attribute_30_name VARCHAR2(200 BYTE),
  line_attribute_31_name VARCHAR2(200 BYTE),
  line_attribute_32_name VARCHAR2(200 BYTE),
  line_attribute_33_name VARCHAR2(200 BYTE),
  line_attribute_34_name VARCHAR2(200 BYTE),
  line_attribute_35_name VARCHAR2(200 BYTE),
  line_attribute_36_name VARCHAR2(200 BYTE),
  line_attribute_37_name VARCHAR2(200 BYTE),
  line_attribute_38_name VARCHAR2(200 BYTE),
  line_attribute_39_name VARCHAR2(200 BYTE),
  line_attribute_3_name VARCHAR2(200 BYTE),
  line_attribute_40_name VARCHAR2(200 BYTE),
  line_attribute_41_name VARCHAR2(200 BYTE),
  line_attribute_42_name VARCHAR2(200 BYTE),
  line_attribute_43_name VARCHAR2(200 BYTE),
  line_attribute_44_name VARCHAR2(200 BYTE),
  line_attribute_45_name VARCHAR2(200 BYTE),
  line_attribute_46_name VARCHAR2(200 BYTE),
  line_attribute_47_name VARCHAR2(200 BYTE),
  line_attribute_48_name VARCHAR2(200 BYTE),
  line_attribute_49_name VARCHAR2(200 BYTE),
  line_attribute_4_name VARCHAR2(200 BYTE),
  line_attribute_50_name VARCHAR2(200 BYTE),
  line_attribute_5_name VARCHAR2(200 BYTE),
  line_attribute_6_name VARCHAR2(200 BYTE),
  line_attribute_7_name VARCHAR2(200 BYTE),
  line_attribute_8_name VARCHAR2(200 BYTE),
  line_attribute_9_name VARCHAR2(200 BYTE),
  merchant_id NUMBER(10),
  merchant_type VARCHAR2(1 BYTE),
  "NAME" VARCHAR2(100 BYTE),
  notes VARCHAR2(2000 BYTE),
  parent_merchant_id NUMBER(10),
  product_cross_ref_group_id NUMBER(10),
  product_qual_group_name VARCHAR2(100 BYTE),
  product_qual_group_owner_id NUMBER(10),
  registration_group_id NUMBER(10),
  short_name VARCHAR2(10 BYTE),
  source_system_id VARCHAR2(100 BYTE),
  splash_url VARCHAR2(200 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  tax_code_qual_group_name VARCHAR2(100 BYTE),
  tax_code_qual_group_owner_id NUMBER(10),
  uses_exempt_certs VARCHAR2(1 BYTE),
  us_content_provider_id NUMBER(10),
  us_custom_data_provider_id NUMBER(10),
  us_established_merchant_id NUMBER(10),
  us_exchange_rate_merchant_id NUMBER(10),
  us_product_group_id NUMBER(10),
  xml_error_threshold NUMBER(10),
  xml_group_id NUMBER(10),
  aud_merchant_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;