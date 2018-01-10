CREATE TABLE sbxtax4.pvw_tb_rule_qualifiers (
  authority VARCHAR2(400 CHAR),
  authority_id NUMBER,
  "ELEMENT" VARCHAR2(800 CHAR) NOT NULL,
  element_type VARCHAR2(200 CHAR),
  element_value VARCHAR2(800 CHAR),
  end_date DATE,
  is_local VARCHAR2(4 CHAR),
  "OPERATOR" VARCHAR2(200 CHAR) NOT NULL,
  product_category_id NUMBER,
  reference_list_id NUMBER,
  reference_list_name VARCHAR2(400 CHAR),
  rule_authority_id NUMBER,
  rule_id NUMBER,
  rule_order NUMBER,
  rule_qualifier_id NUMBER,
  rule_qualifier_type VARCHAR2(200 CHAR),
  rule_start_date DATE,
  start_date DATE NOT NULL,
  "VALUE" VARCHAR2(800 CHAR),
  value_type VARCHAR2(200 CHAR),
  rule_authority_uuid VARCHAR2(36 CHAR)
) 
TABLESPACE ositax;