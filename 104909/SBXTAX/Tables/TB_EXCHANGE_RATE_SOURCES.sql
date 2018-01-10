CREATE TABLE sbxtax.tb_exchange_rate_sources (
  exchange_rate_source_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  intermediate_currency_id NUMBER,
  source_name VARCHAR2(100 CHAR) NOT NULL,
  description VARCHAR2(1200 CHAR),
  service_type VARCHAR2(100 CHAR) NOT NULL,
  service_location VARCHAR2(380 CHAR) NOT NULL,
  update_frequency VARCHAR2(10 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax
LOB (description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);