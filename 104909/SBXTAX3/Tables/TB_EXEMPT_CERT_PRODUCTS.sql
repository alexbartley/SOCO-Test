CREATE TABLE sbxtax3.tb_exempt_cert_products (
  exempt_cert_product_id NUMBER(10) NOT NULL,
  exempt_cert_id NUMBER(10) NOT NULL,
  prod_code_match VARCHAR2(100 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;