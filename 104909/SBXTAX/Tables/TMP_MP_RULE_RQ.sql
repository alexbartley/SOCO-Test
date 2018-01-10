CREATE TABLE sbxtax.tmp_mp_rule_rq (
  rule_id NUMBER,
  rule_qualifier_set VARCHAR2(1000 CHAR),
  authority_uuid VARCHAR2(36 CHAR),
  start_date DATE,
  end_date DATE
) 
TABLESPACE ositax;