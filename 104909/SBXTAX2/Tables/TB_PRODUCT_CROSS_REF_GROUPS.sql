CREATE TABLE sbxtax2.tb_product_cross_ref_groups (
  product_cross_ref_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 BYTE),
  description VARCHAR2(500 BYTE),
  merchant_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;