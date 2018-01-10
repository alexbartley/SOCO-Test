CREATE TABLE sbxtax4.tb_product_cross_ref_groups (
  product_cross_ref_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR),
  description VARCHAR2(500 CHAR),
  merchant_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;