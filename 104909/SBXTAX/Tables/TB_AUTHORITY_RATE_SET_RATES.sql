CREATE TABLE sbxtax.tb_authority_rate_set_rates (
  authority_rate_set_rate_id NUMBER NOT NULL,
  authority_rate_set_id NUMBER NOT NULL,
  process_order NUMBER(31,10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  product_category_id NUMBER,
  material_set_list_id NUMBER,
  rate_code VARCHAR2(50 CHAR) NOT NULL,
  erp_tax_code VARCHAR2(200 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;