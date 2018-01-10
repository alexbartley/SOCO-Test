CREATE TABLE sbxtax3.tb_product_groups (
  product_group_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(200 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  content_type VARCHAR2(50 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;