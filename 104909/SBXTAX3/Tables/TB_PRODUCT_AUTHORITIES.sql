CREATE TABLE sbxtax3.tb_product_authorities (
  product_authority_id NUMBER(10) NOT NULL,
  authority_id NUMBER(10),
  "EXEMPT" VARCHAR2(1 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  product_category_id NUMBER(10),
  start_date DATE NOT NULL,
  end_date DATE,
  override_locals VARCHAR2(1 BYTE),
  authority_type_id NUMBER(10),
  zone_id NUMBER(10) NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;