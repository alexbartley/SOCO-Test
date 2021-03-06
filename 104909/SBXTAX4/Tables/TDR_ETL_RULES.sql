CREATE TABLE sbxtax4.tdr_etl_rules (
  "ID" NUMBER,
  authority_uuid VARCHAR2(36 CHAR),
  calculation_method NUMBER,
  basis_percent NUMBER,
  rate_code VARCHAR2(32 CHAR),
  "EXEMPT" VARCHAR2(1 CHAR),
  no_tax VARCHAR2(1 CHAR),
  tax_type VARCHAR2(16 CHAR),
  start_date DATE,
  end_date DATE,
  recoverable_percent NUMBER,
  rule_order NUMBER,
  commodity_nkid NUMBER,
  highest VARCHAR2(2 CHAR),
  hierarchy_level NUMBER,
  sibling_order NUMBER,
  rule_qualifier_set VARCHAR2(1000 CHAR),
  rule_qual_order NUMBER,
  is_local VARCHAR2(1 CHAR),
  nkid NUMBER,
  commodity_id NUMBER,
  extract_id NUMBER,
  rid NUMBER,
  recoverable_amount NUMBER,
  allocated_charge VARCHAR2(1 CHAR),
  related_charge VARCHAR2(1 CHAR),
  ref_rule_order NUMBER,
  unit_of_measure VARCHAR2(20 BYTE),
  default_taxability VARCHAR2(1 BYTE)
) 
TABLESPACE ositax;