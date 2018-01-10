CREATE TABLE sbxtax4.tb_product_authorities (
  product_authority_id NUMBER NOT NULL,
  authority_id NUMBER,
  "EXEMPT" VARCHAR2(1 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  product_category_id NUMBER,
  start_date DATE NOT NULL,
  end_date DATE,
  override_locals VARCHAR2(1 CHAR),
  authority_type_id NUMBER,
  zone_id NUMBER NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;