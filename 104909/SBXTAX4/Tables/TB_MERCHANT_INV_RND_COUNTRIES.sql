CREATE TABLE sbxtax4.tb_merchant_inv_rnd_countries (
  merchant_inv_rnd_country_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  country_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;