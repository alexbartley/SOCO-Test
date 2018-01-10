CREATE TABLE sbxtax.tb_rates (
  rate_id NUMBER(10) NOT NULL,
  rate_code VARCHAR2(50 BYTE) NOT NULL,
  description VARCHAR2(100 BYTE),
  rate NUMBER(31,10),
  authority_id NUMBER(10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  merchant_id NUMBER(10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  split_type VARCHAR2(2 BYTE),
  split_amount_type VARCHAR2(1 BYTE),
  is_local VARCHAR2(1 BYTE),
  flat_fee NUMBER(31,5),
  currency_id NUMBER(10),
  unit_of_measure_code VARCHAR2(25 BYTE) NOT NULL,
  use_default_qty VARCHAR2(1 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  min_amount NUMBER(31,5)
) 
TABLESPACE ositax;