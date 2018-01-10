CREATE TABLE sbxtax4.tmp_rule_qualifiers_11_16 (
  authority_uuid VARCHAR2(36 CHAR),
  jta_nkid NUMBER,
  taxability_element VARCHAR2(50 CHAR),
  logical_qualifier VARCHAR2(32 CHAR),
  "VALUE" VARCHAR2(1000 CHAR),
  start_date DATE,
  end_date DATE,
  reference_group_nkid NUMBER,
  extract_id NUMBER,
  rule_qualifier_set VARCHAR2(1000 CHAR),
  reference_group_name VARCHAR2(100 CHAR),
  nkid NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;