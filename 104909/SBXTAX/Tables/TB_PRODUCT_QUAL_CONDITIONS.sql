CREATE TABLE sbxtax.tb_product_qual_conditions (
  product_qual_condition_id NUMBER NOT NULL,
  product_qualifier_id NUMBER NOT NULL,
  ordering NUMBER(10) NOT NULL,
  xml_element VARCHAR2(100 CHAR),
  "OPERATOR" VARCHAR2(15 CHAR),
  "VALUE" VARCHAR2(250 CHAR),
  reference_list_id NUMBER,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;