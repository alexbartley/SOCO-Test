CREATE TABLE content_repo.impl_expl_raw_ds (
  processid NUMBER,
  implicit NUMBER,
  implexpl_auth_level NUMBER,
  impl_cm_order NUMBER,
  "ID" NUMBER,
  reference_code VARCHAR2(100 CHAR) NOT NULL,
  calculation_method_id NUMBER NOT NULL,
  basis_percent NUMBER,
  recoverable_percent NUMBER,
  recoverable_amount NUMBER,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status NUMBER NOT NULL,
  status_modified_date TIMESTAMP WITH TIME ZONE NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER(22),
  jurisdiction_id NUMBER,
  jurisdiction_nkid NUMBER NOT NULL,
  jurisdiction_rid NUMBER,
  jurisdiction_official_name VARCHAR2(256 BYTE),
  all_taxes_apply NUMBER(1) NOT NULL,
  applicability_type_id NUMBER NOT NULL,
  charge_type_id NUMBER,
  unit_of_measure VARCHAR2(16 CHAR),
  ref_rule_order NUMBER,
  default_taxability NUMBER,
  product_tree_id NUMBER,
  commodity_id NUMBER,
  commodity_nkid NUMBER,
  commodity_rid NUMBER,
  commodity_name VARCHAR2(500 BYTE),
  commodity_code VARCHAR2(100 CHAR),
  h_code VARCHAR2(128 CHAR),
  conditions CHAR,
  tax_type VARCHAR2(4 CHAR),
  tax_applicabilities VARCHAR2(32767 CHAR),
  verification CHAR(7 BYTE),
  change_count NUMBER,
  commodity_tree_id NUMBER,
  is_local NUMBER,
  legal_statement VARCHAR2(500 CHAR),
  canbedeleted NUMBER,
  maxstatus NUMBER,
  tag_collection VARCHAR2(32767 BYTE),
  condition_collection VARCHAR2(32767 BYTE),
  applicable_tax_collection VARCHAR2(32767 BYTE),
  processing_order NUMBER,
  verifylist VARCHAR2(32767 BYTE),
  source_h_code VARCHAR2(128 BYTE)
) 
TABLESPACE content_repo
LOB (applicable_tax_collection) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (condition_collection) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (tag_collection) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (tax_applicabilities) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (verifylist) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
PARALLEL 4;