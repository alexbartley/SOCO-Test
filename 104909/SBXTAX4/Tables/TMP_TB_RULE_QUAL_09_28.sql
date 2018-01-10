CREATE TABLE sbxtax4.tmp_tb_rule_qual_09_28 (
  rule_qualifier_id NUMBER NOT NULL,
  rule_id NUMBER NOT NULL,
  rule_qualifier_type VARCHAR2(50 CHAR),
  "ELEMENT" VARCHAR2(200 CHAR) NOT NULL,
  "OPERATOR" VARCHAR2(50 CHAR) NOT NULL,
  "VALUE" VARCHAR2(200 CHAR),
  value_type VARCHAR2(50 CHAR),
  element_type VARCHAR2(50 CHAR),
  element_value VARCHAR2(200 CHAR),
  reference_list_id NUMBER,
  authority_id NUMBER,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP
) 
TABLESPACE ositax;