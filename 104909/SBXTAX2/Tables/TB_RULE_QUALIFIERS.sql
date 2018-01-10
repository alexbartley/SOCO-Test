CREATE TABLE sbxtax2.tb_rule_qualifiers (
  rule_qualifier_id NUMBER(10) NOT NULL,
  rule_id NUMBER(10) NOT NULL,
  rule_qualifier_type VARCHAR2(50 BYTE),
  "ELEMENT" VARCHAR2(200 BYTE) NOT NULL,
  "OPERATOR" VARCHAR2(50 BYTE) NOT NULL,
  "VALUE" VARCHAR2(200 BYTE),
  value_type VARCHAR2(50 BYTE),
  element_type VARCHAR2(50 BYTE),
  element_value VARCHAR2(200 BYTE),
  reference_list_id NUMBER(10),
  authority_id NUMBER(10),
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;