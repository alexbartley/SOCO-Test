CREATE TABLE sbxtax2.tb_merchants (
  merchant_id NUMBER NOT NULL,
  "ACTIVE" VARCHAR2(1 BYTE) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  short_name VARCHAR2(10 BYTE),
  notes VARCHAR2(2000 BYTE),
  creation_date DATE NOT NULL,
  last_update_date DATE,
  last_updated_by NUMBER(10),
  parent_merchant_id NUMBER,
  created_by NUMBER,
  xml_error_threshold NUMBER,
  xml_group_id NUMBER,
  splash_url VARCHAR2(200 BYTE),
  is_content_provider VARCHAR2(1 BYTE),
  b2b_flag VARCHAR2(1 BYTE),
  source_system_id VARCHAR2(100 BYTE),
  customer_group_id NUMBER,
  uses_exempt_certs VARCHAR2(1 BYTE),
  registration_group_id NUMBER,
  create_auto_certs VARCHAR2(1 BYTE),
  create_customers VARCHAR2(1 BYTE),
  days_valid NUMBER,
  default_cert_status VARCHAR2(1 BYTE),
  exempt_temp_cert_trans VARCHAR2(1 BYTE),
  us_content_provider_id NUMBER,
  intl_content_provider_id NUMBER,
  content_version VARCHAR2(20 BYTE),
  content_comment VARCHAR2(50 BYTE),
  content_type VARCHAR2(100 BYTE),
  def_intl_exempt_reason_id NUMBER,
  def_us_exempt_reason_id NUMBER,
  b2b_create_merchant VARCHAR2(1 BYTE),
  b2b_parent_merchant_id NUMBER,
  b2b_use_parent_prefs VARCHAR2(1 BYTE),
  product_cross_ref_group_id NUMBER,
  us_established_merchant_id NUMBER,
  intl_established_merchant_id NUMBER,
  us_custom_data_provider_id NUMBER,
  intl_custom_data_provider_id NUMBER,
  inv_attribute_1_name VARCHAR2(200 BYTE),
  inv_attribute_2_name VARCHAR2(200 BYTE),
  inv_attribute_3_name VARCHAR2(200 BYTE),
  inv_attribute_4_name VARCHAR2(200 BYTE),
  inv_attribute_5_name VARCHAR2(200 BYTE),
  inv_attribute_6_name VARCHAR2(200 BYTE),
  inv_attribute_7_name VARCHAR2(200 BYTE),
  inv_attribute_8_name VARCHAR2(200 BYTE),
  inv_attribute_9_name VARCHAR2(200 BYTE),
  inv_attribute_10_name VARCHAR2(200 BYTE),
  line_attribute_1_name VARCHAR2(200 BYTE),
  line_attribute_2_name VARCHAR2(200 BYTE),
  line_attribute_3_name VARCHAR2(200 BYTE),
  line_attribute_4_name VARCHAR2(200 BYTE),
  line_attribute_5_name VARCHAR2(200 BYTE),
  line_attribute_6_name VARCHAR2(200 BYTE),
  line_attribute_7_name VARCHAR2(200 BYTE),
  line_attribute_8_name VARCHAR2(200 BYTE),
  line_attribute_9_name VARCHAR2(200 BYTE),
  line_attribute_10_name VARCHAR2(200 BYTE),
  filter_group_owner_id NUMBER,
  filter_group_name VARCHAR2(100 BYTE),
  line_attribute_24_name VARCHAR2(200 BYTE),
  line_attribute_25_name VARCHAR2(200 BYTE),
  line_attribute_26_name VARCHAR2(200 BYTE),
  line_attribute_27_name VARCHAR2(200 BYTE),
  line_attribute_28_name VARCHAR2(200 BYTE),
  line_attribute_29_name VARCHAR2(200 BYTE),
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
  line_attribute_50_name VARCHAR2(200 BYTE),
  legal_entity_name VARCHAR2(200 BYTE),
  merchant_type VARCHAR2(1 BYTE),
  inv_attribute_11_name VARCHAR2(200 BYTE),
  inv_attribute_12_name VARCHAR2(200 BYTE),
  inv_attribute_13_name VARCHAR2(200 BYTE),
  inv_attribute_14_name VARCHAR2(200 BYTE),
  inv_attribute_15_name VARCHAR2(200 BYTE),
  inv_attribute_16_name VARCHAR2(200 BYTE),
  inv_attribute_17_name VARCHAR2(200 BYTE),
  inv_attribute_18_name VARCHAR2(200 BYTE),
  inv_attribute_19_name VARCHAR2(200 BYTE),
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
  inv_attribute_50_name VARCHAR2(200 BYTE),
  line_attribute_11_name VARCHAR2(200 BYTE),
  line_attribute_12_name VARCHAR2(200 BYTE),
  line_attribute_13_name VARCHAR2(200 BYTE),
  line_attribute_14_name VARCHAR2(200 BYTE),
  line_attribute_15_name VARCHAR2(200 BYTE),
  line_attribute_16_name VARCHAR2(200 BYTE),
  line_attribute_17_name VARCHAR2(200 BYTE),
  line_attribute_18_name VARCHAR2(200 BYTE),
  line_attribute_19_name VARCHAR2(200 BYTE),
  line_attribute_20_name VARCHAR2(200 BYTE),
  line_attribute_21_name VARCHAR2(200 BYTE),
  line_attribute_22_name VARCHAR2(200 BYTE),
  line_attribute_23_name VARCHAR2(200 BYTE),
  allocation_group_owner_id NUMBER,
  allocation_group_name VARCHAR2(100 BYTE),
  is_auditing_messages VARCHAR2(1 BYTE),
  audit_message_threshold NUMBER,
  is_using_reporting_periods VARCHAR2(1 BYTE),
  external_token VARCHAR2(36 BYTE) DEFAULT '.' NOT NULL,
  us_exchange_rate_merchant_id NUMBER(10),
  intl_exchange_rate_merchant_id NUMBER(10),
  us_product_group_id NUMBER(10),
  intl_product_group_id NUMBER(10),
  product_qual_group_owner_id NUMBER(10),
  product_qual_group_name VARCHAR2(100 BYTE),
  tax_code_qual_group_owner_id NUMBER(10),
  tax_code_qual_group_name VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;