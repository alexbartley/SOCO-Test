CREATE TABLE content_repo.osr_rates_tmp (
  state_code VARCHAR2(2 CHAR),
  "ID" NUMBER,
  nkid NUMBER,
  rid NUMBER,
  next_rid NUMBER,
  juris_tax_entity_rid NUMBER,
  juris_tax_next_rid NUMBER,
  reference_code VARCHAR2(100 CHAR),
  start_date DATE,
  end_date DATE,
  taxation_type_id NUMBER,
  taxation_type VARCHAR2(500 CHAR),
  spec_applicability_type_id NUMBER,
  specific_applicability_type VARCHAR2(500 CHAR),
  transaction_type_id NUMBER,
  transaction_type VARCHAR2(50 CHAR),
  tax_structure_type_id NUMBER,
  tax_structure VARCHAR2(500 CHAR),
  value_type VARCHAR2(25 CHAR),
  min_threshold NUMBER,
  max_limit NUMBER,
  tax_value NUMBER,
  official_name VARCHAR2(250 CHAR),
  jurisdiction_id NUMBER,
  jurisdiction_rid NUMBER,
  jurisdiction_nkid NUMBER,
  ref_juris_tax_rid NUMBER,
  status NUMBER,
  tax_description VARCHAR2(250 CHAR),
  tax_shipping_alone VARCHAR2(1 CHAR),
  tax_shipping_and_handling VARCHAR2(1 CHAR),
  location_category VARCHAR2(25 CHAR),
  admin_name VARCHAR2(250 CHAR),
  reporting_code VARCHAR2(50 CHAR)
) 
TABLESPACE content_repo;