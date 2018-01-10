CREATE TABLE sbxtax4.tmp_taxability_products (
  jta_nkid NUMBER,
  tas_nkid NUMBER,
  commodity_nkid NUMBER,
  start_date DATE,
  end_date DATE,
  invoice_description VARCHAR2(100 CHAR),
  hierarchy_level NUMBER,
  nkid NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;