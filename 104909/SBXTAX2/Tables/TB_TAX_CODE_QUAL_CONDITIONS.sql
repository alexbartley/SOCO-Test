CREATE TABLE sbxtax2.tb_tax_code_qual_conditions (
  tax_code_qual_condition_id NUMBER(10) NOT NULL,
  tax_code_qualifier_id NUMBER(10) NOT NULL,
  ordering NUMBER(10) NOT NULL,
  xml_element VARCHAR2(100 BYTE),
  "OPERATOR" VARCHAR2(15 BYTE),
  "VALUE" VARCHAR2(250 BYTE),
  reference_list_id NUMBER(10),
  use_delimiter VARCHAR2(1 BYTE),
  concatenation_value VARCHAR2(200 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;