CREATE TABLE sbxtax2.harmonized_2007_vs_sabrix (
  sabrix_commodity_code VARCHAR2(50 BYTE),
  parent_product VARCHAR2(100 BYTE),
  sabrix_product_name VARCHAR2(100 BYTE),
  hlevel NUMBER,
  h2007_commodity_code VARCHAR2(50 BYTE),
  h2007_product_name VARCHAR2(1000 BYTE)
) 
TABLESPACE ositax;