CREATE TABLE sbxtax.tb_tax_code_qualifiers (
  tax_code_qualifier_id NUMBER NOT NULL,
  tax_code_qualifier_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  erp_tax_code VARCHAR2(200 CHAR),
  concatenation_delimiter VARCHAR2(1 CHAR),
  ordering NUMBER(10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;