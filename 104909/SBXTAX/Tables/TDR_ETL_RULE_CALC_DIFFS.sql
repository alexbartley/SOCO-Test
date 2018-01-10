CREATE TABLE sbxtax.tdr_etl_rule_calc_diffs (
  jta_nkid NUMBER,
  calculation_method NUMBER,
  basis_percent NUMBER,
  recoverable_percent NUMBER,
  start_date DATE,
  end_date DATE,
  "ACTION" VARCHAR2(50 CHAR),
  recoverable_amount NUMBER,
  ref_rule_order NUMBER,
  commodity_id NUMBER,
  commodity_nkid NUMBER,
  default_taxability VARCHAR2(1 BYTE),
  applicability_type_id NUMBER,
  unit_of_measure VARCHAR2(20 BYTE),
  charge_type_id NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;