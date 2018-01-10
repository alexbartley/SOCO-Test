CREATE TABLE sbxtax2.tb_product_categories (
  product_category_id NUMBER NOT NULL,
  product_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(250 BYTE),
  notc VARCHAR2(20 BYTE),
  parent_product_category_id NUMBER,
  merchant_id NUMBER NOT NULL,
  prodcode VARCHAR2(50 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;