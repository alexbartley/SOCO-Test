CREATE TABLE sbxtax3.a_product_categories (
  product_category_id NUMBER(10),
  product_group_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  description VARCHAR2(250 BYTE),
  notc VARCHAR2(20 BYTE),
  parent_product_category_id NUMBER(10),
  merchant_id NUMBER(10),
  prodcode VARCHAR2(50 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  product_category_id_o NUMBER(10),
  product_group_id_o NUMBER(10),
  name_o VARCHAR2(100 BYTE),
  description_o VARCHAR2(250 BYTE),
  notc_o VARCHAR2(20 BYTE),
  parent_product_category_id_o NUMBER(10),
  merchant_id_o NUMBER(10),
  prodcode_o VARCHAR2(50 BYTE),
  created_by_o NUMBER(10),
  creation_date_o DATE,
  last_updated_by_o NUMBER(10),
  last_update_date_o DATE,
  change_type VARCHAR2(20 BYTE) NOT NULL,
  change_version VARCHAR2(50 BYTE),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;