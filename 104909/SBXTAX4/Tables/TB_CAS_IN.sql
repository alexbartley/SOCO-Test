CREATE TABLE sbxtax4.tb_cas_in (
  invoice_date DATE,
  record_number NUMBER(8),
  sstpsst_id VARCHAR2(10 CHAR),
  misc_id NUMBER,
  "STATE" VARCHAR2(2 CHAR),
  delivery_method VARCHAR2(1 CHAR),
  customer_entity_code VARCHAR2(1 CHAR),
  ship_to_address VARCHAR2(40 CHAR),
  ship_to_suite VARCHAR2(40 CHAR),
  ship_to_city VARCHAR2(40 CHAR),
  ship_to_state VARCHAR2(2 CHAR),
  ship_to_zip NUMBER(5),
  ship_to_geocode NUMBER(4),
  sku NUMBER(19),
  sale_amount NUMBER(38)
) 
TABLESPACE ositax;