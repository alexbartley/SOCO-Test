CREATE TABLE sbxtax3.pt_product_tree_sort (
  sort_key VARCHAR2(167 BYTE),
  prodcode VARCHAR2(50 BYTE),
  product_group_id NUMBER NOT NULL,
  product_name VARCHAR2(100 BYTE) NOT NULL,
  merchant_id NUMBER NOT NULL,
  primary_key NUMBER NOT NULL,
  product_1_id NUMBER NOT NULL,
  product_1_name VARCHAR2(100 BYTE) NOT NULL,
  product_2_id NUMBER,
  product_2_name VARCHAR2(100 BYTE),
  product_3_id NUMBER,
  product_3_name VARCHAR2(100 BYTE),
  product_4_id NUMBER,
  product_4_name VARCHAR2(100 BYTE),
  product_5_id NUMBER,
  product_5_name VARCHAR2(100 BYTE),
  product_6_id NUMBER,
  product_6_name VARCHAR2(100 BYTE),
  product_7_id NUMBER,
  product_7_name VARCHAR2(100 BYTE),
  product_8_id NUMBER,
  product_8_name VARCHAR2(100 BYTE),
  product_9_id NUMBER,
  product_9_name VARCHAR2(100 BYTE)
) 
TABLESPACE ositax;