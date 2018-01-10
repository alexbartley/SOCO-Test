CREATE TABLE sbxtax.tdr_etl_rule_qual_diffs (
  jta_nkid NUMBER,
  "ELEMENT" VARCHAR2(250 CHAR),
  "OPERATOR" VARCHAR2(50 CHAR),
  "VALUE" VARCHAR2(500 CHAR),
  reference_group_nkid NUMBER,
  jurisdiction_nkid NUMBER,
  start_date DATE,
  end_date DATE,
  "ACTION" VARCHAR2(50 CHAR)
) 
TABLESPACE ositax;