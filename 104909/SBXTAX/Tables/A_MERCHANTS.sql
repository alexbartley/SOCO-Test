CREATE TABLE sbxtax.a_merchants (
  merchant_id NUMBER,
  "ACTIVE" VARCHAR2(1 CHAR),
  "NAME" VARCHAR2(100 CHAR),
  short_name VARCHAR2(10 CHAR),
  legal_entity_name VARCHAR2(200 CHAR),
  merchant_type VARCHAR2(1 CHAR),
  external_token VARCHAR2(36 CHAR),
  notes VARCHAR2(2000 CHAR),
  parent_merchant_id NUMBER,
  created_by NUMBER,
  xml_error_threshold NUMBER,
  xml_group_id NUMBER,
  splash_url VARCHAR2(200 CHAR),
  is_content_provider VARCHAR2(1 CHAR),
  b2b_flag VARCHAR2(1 CHAR),
  filter_group_owner_id NUMBER,
  filter_group_name VARCHAR2(100 CHAR),
  product_qual_group_owner_id NUMBER,
  product_qual_group_name VARCHAR2(100 CHAR),
  tax_code_qual_group_owner_id NUMBER,
  tax_code_qual_group_name VARCHAR2(100 CHAR),
  source_system_id VARCHAR2(100 CHAR),
  customer_group_id NUMBER,
  uses_exempt_certs VARCHAR2(1 CHAR),
  registration_group_id NUMBER,
  create_auto_certs VARCHAR2(1 CHAR),
  create_customers VARCHAR2(1 CHAR),
  days_valid NUMBER,
  default_cert_status VARCHAR2(1 CHAR),
  exempt_temp_cert_trans VARCHAR2(1 CHAR),
  us_content_provider_id NUMBER,
  intl_content_provider_id NUMBER,
  content_version VARCHAR2(20 CHAR),
  content_comment VARCHAR2(50 CHAR),
  content_type VARCHAR2(100 CHAR),
  def_intl_exempt_reason_id NUMBER,
  def_us_exempt_reason_id NUMBER,
  b2b_create_merchant VARCHAR2(1 CHAR),
  b2b_parent_merchant_id NUMBER,
  b2b_use_parent_prefs VARCHAR2(1 CHAR),
  product_cross_ref_group_id NUMBER,
  us_established_merchant_id NUMBER,
  intl_established_merchant_id NUMBER,
  us_custom_data_provider_id NUMBER,
  intl_custom_data_provider_id NUMBER,
  us_exchange_rate_merchant_id NUMBER,
  intl_exchange_rate_merchant_id NUMBER,
  allocation_group_owner_id NUMBER,
  allocation_group_name VARCHAR2(100 CHAR),
  is_auditing_messages VARCHAR2(1 CHAR),
  audit_message_threshold NUMBER,
  us_product_group_id NUMBER,
  intl_product_group_id NUMBER,
  merchant_id_o NUMBER,
  active_o VARCHAR2(1 CHAR),
  name_o VARCHAR2(100 CHAR),
  short_name_o VARCHAR2(10 CHAR),
  legal_entity_name_o VARCHAR2(200 CHAR),
  merchant_type_o VARCHAR2(1 CHAR),
  external_token_o VARCHAR2(36 CHAR),
  notes_o VARCHAR2(2000 CHAR),
  parent_merchant_id_o NUMBER,
  xml_error_threshold_o NUMBER,
  xml_group_id_o NUMBER,
  splash_url_o VARCHAR2(200 CHAR),
  is_content_provider_o VARCHAR2(1 CHAR),
  b2b_flag_o VARCHAR2(1 CHAR),
  filter_group_owner_id_o NUMBER,
  filter_group_name_o VARCHAR2(100 CHAR),
  product_qual_group_owner_id_o NUMBER,
  product_qual_group_name_o VARCHAR2(100 CHAR),
  tax_code_qual_group_owner_id_o NUMBER,
  tax_code_qual_group_name_o VARCHAR2(100 CHAR),
  source_system_id_o VARCHAR2(100 CHAR),
  customer_group_id_o NUMBER,
  uses_exempt_certs_o VARCHAR2(1 CHAR),
  registration_group_id_o NUMBER,
  create_auto_certs_o VARCHAR2(1 CHAR),
  create_customers_o VARCHAR2(1 CHAR),
  days_valid_o NUMBER,
  default_cert_status_o VARCHAR2(1 CHAR),
  exempt_temp_cert_trans_o VARCHAR2(1 CHAR),
  us_content_provider_id_o NUMBER,
  intl_content_provider_id_o NUMBER,
  content_version_o VARCHAR2(20 CHAR),
  content_comment_o VARCHAR2(50 CHAR),
  content_type_o VARCHAR2(100 CHAR),
  def_intl_exempt_reason_id_o NUMBER,
  def_us_exempt_reason_id_o NUMBER,
  b2b_create_merchant_o VARCHAR2(1 CHAR),
  b2b_parent_merchant_id_o NUMBER,
  b2b_use_parent_prefs_o VARCHAR2(1 CHAR),
  product_cross_ref_group_id_o NUMBER,
  us_established_merchant_id_o NUMBER,
  intl_established_merchant_id_o NUMBER,
  us_custom_data_provider_id_o NUMBER,
  intl_custom_data_provider_id_o NUMBER,
  us_exchange_rate_merchant_id_o NUMBER,
  intl_exchge_rate_merchant_id_o NUMBER,
  change_date DATE NOT NULL
) 
TABLESPACE ositax
LOB (notes) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (notes_o) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);