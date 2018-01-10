CREATE TABLE sbxtax4.tmp_qae_1804_new_telco (
  authority_name VARCHAR2(1000 CHAR),
  rule_order NUMBER(30,10),
  start_date DATE,
  end_date DATE,
  rate_code VARCHAR2(1000 CHAR),
  "EXEMPT" VARCHAR2(100 CHAR),
  no_tax VARCHAR2(100 CHAR),
  commodity_code VARCHAR2(100 CHAR),
  product_name VARCHAR2(1000 CHAR),
  tax_type VARCHAR2(1000 CHAR),
  calculation_method VARCHAR2(1000 CHAR),
  invoice_description VARCHAR2(1000 CHAR),
  basis_percent NUMBER,
  cascading VARCHAR2(1000 CHAR),
  tax_code VARCHAR2(1000 CHAR)
) 
TABLESPACE ositax;