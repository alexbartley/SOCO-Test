CREATE TABLE sbxtax4.pt_catch_all (
  product_category_id NUMBER NOT NULL,
  tax_type VARCHAR2(100 BYTE),
  authority VARCHAR2(100 BYTE) NOT NULL,
  product_group_id NUMBER NOT NULL,
  auth_default_product_group NUMBER NOT NULL,
  taxability VARCHAR2(50 BYTE) NOT NULL,
  updated_date DATE NOT NULL,
  merchant_id NUMBER NOT NULL
) 
TABLESPACE ositax;