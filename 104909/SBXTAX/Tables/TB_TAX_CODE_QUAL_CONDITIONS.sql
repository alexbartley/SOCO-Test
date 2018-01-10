CREATE TABLE sbxtax.tb_tax_code_qual_conditions (
  tax_code_qual_condition_id NUMBER NOT NULL,
  tax_code_qualifier_id NUMBER NOT NULL,
  ordering NUMBER(10) NOT NULL,
  xml_element VARCHAR2(100 CHAR),
  "OPERATOR" VARCHAR2(15 CHAR),
  "VALUE" VARCHAR2(250 CHAR),
  reference_list_id NUMBER,
  use_delimiter VARCHAR2(1 CHAR),
  concatenation_value VARCHAR2(200 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;