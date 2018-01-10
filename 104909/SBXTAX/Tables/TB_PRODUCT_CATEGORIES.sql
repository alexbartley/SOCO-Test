CREATE TABLE sbxtax.tb_product_categories (
  product_category_id NUMBER NOT NULL,
  product_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  description VARCHAR2(250 CHAR),
  notc VARCHAR2(20 CHAR),
  parent_product_category_id NUMBER,
  merchant_id NUMBER NOT NULL,
  prodcode VARCHAR2(50 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;