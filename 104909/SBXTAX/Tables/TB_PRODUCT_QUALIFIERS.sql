CREATE TABLE sbxtax.tb_product_qualifiers (
  product_qualifier_id NUMBER NOT NULL,
  product_qualifier_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  product_code VARCHAR2(100 CHAR),
  commodity_code VARCHAR2(50 CHAR),
  transaction_type VARCHAR2(2 CHAR),
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