CREATE TABLE sbxtax.a_product_categories (
  product_category_id NUMBER,
  product_group_id NUMBER,
  "NAME" VARCHAR2(100 CHAR),
  description VARCHAR2(250 CHAR),
  notc VARCHAR2(20 CHAR),
  parent_product_category_id NUMBER,
  merchant_id NUMBER,
  prodcode VARCHAR2(50 CHAR),
  created_by NUMBER,
  creation_date DATE,
  last_updated_by NUMBER,
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP,
  product_category_id_o NUMBER,
  product_group_id_o NUMBER,
  name_o VARCHAR2(100 CHAR),
  description_o VARCHAR2(250 CHAR),
  notc_o VARCHAR2(20 CHAR),
  parent_product_category_id_o NUMBER,
  merchant_id_o NUMBER,
  prodcode_o VARCHAR2(50 CHAR),
  created_by_o NUMBER,
  creation_date_o DATE,
  last_updated_by_o NUMBER,
  last_update_date_o DATE,
  synchronization_timestamp_o TIMESTAMP,
  change_type VARCHAR2(20 CHAR) NOT NULL,
  change_version VARCHAR2(50 CHAR),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;