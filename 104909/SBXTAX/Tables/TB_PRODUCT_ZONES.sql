CREATE TABLE sbxtax.tb_product_zones (
  product_zone_id NUMBER NOT NULL,
  product_category_id NUMBER NOT NULL,
  zone_id NUMBER NOT NULL,
  exempt_type VARCHAR2(10 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  start_date DATE NOT NULL,
  end_date DATE,
  override_locals VARCHAR2(1 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;