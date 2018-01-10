CREATE TABLE sbxtax3.tb_exchange_rate_sources (
  exchange_rate_source_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  intermediate_currency_id NUMBER(10),
  source_name VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(1200 BYTE),
  service_type VARCHAR2(100 BYTE) NOT NULL,
  service_location VARCHAR2(380 BYTE) NOT NULL,
  update_frequency VARCHAR2(10 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;