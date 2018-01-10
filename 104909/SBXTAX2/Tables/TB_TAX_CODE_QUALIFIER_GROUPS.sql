CREATE TABLE sbxtax2.tb_tax_code_qualifier_groups (
  tax_code_qualifier_group_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  use_concatenation VARCHAR2(1 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;