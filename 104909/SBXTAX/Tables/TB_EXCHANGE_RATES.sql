CREATE TABLE sbxtax.tb_exchange_rates (
  exchange_rate_id NUMBER NOT NULL,
  exchange_rate_source_id NUMBER NOT NULL,
  from_currency_id NUMBER NOT NULL,
  to_currency_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  rate NUMBER(31,10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;