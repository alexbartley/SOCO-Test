CREATE TABLE sbxtax2.tb_product_authority_types (
  product_authority_type_id NUMBER NOT NULL,
  product_category_id NUMBER NOT NULL,
  authority_type_id NUMBER,
  default_exempt VARCHAR2(1 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  start_date DATE NOT NULL,
  end_date DATE,
  override_locals VARCHAR2(1 BYTE),
  zone_id NUMBER NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;