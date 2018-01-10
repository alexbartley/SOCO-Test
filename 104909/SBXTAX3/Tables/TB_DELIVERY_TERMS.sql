CREATE TABLE sbxtax3.tb_delivery_terms (
  delivery_term_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  delivery_term_code VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(1000 BYTE),
  lookup_id NUMBER(10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;