CREATE TABLE sbxtax.a_rates (
  rate_id NUMBER,
  rate_code VARCHAR2(50 CHAR),
  description VARCHAR2(100 CHAR),
  rate NUMBER(31,10),
  flat_fee NUMBER(31,5),
  currency_id NUMBER,
  unit_of_measure_code VARCHAR2(25 CHAR),
  use_default_qty VARCHAR2(1 CHAR),
  merchant_id NUMBER,
  authority_id NUMBER,
  start_date DATE,
  end_date DATE,
  created_by NUMBER,
  creation_date DATE,
  last_updated_by NUMBER,
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP,
  split_type VARCHAR2(2 CHAR),
  split_amount_type VARCHAR2(1 CHAR),
  is_local VARCHAR2(1 CHAR),
  rate_id_o NUMBER,
  rate_code_o VARCHAR2(50 CHAR),
  description_o VARCHAR2(100 CHAR),
  rate_o NUMBER(31,10),
  flat_fee_o NUMBER(31,5),
  currency_id_o NUMBER,
  unit_of_measure_code_o VARCHAR2(25 CHAR),
  use_default_qty_o VARCHAR2(1 CHAR),
  merchant_id_o NUMBER,
  authority_id_o NUMBER,
  start_date_o DATE,
  end_date_o DATE,
  created_by_o NUMBER,
  creation_date_o DATE,
  last_updated_by_o NUMBER,
  last_update_date_o DATE,
  synchronization_timestamp_o TIMESTAMP,
  split_type_o VARCHAR2(2 CHAR),
  split_amount_type_o VARCHAR2(1 CHAR),
  is_local_o VARCHAR2(1 CHAR),
  change_type VARCHAR2(20 CHAR) NOT NULL,
  change_version VARCHAR2(50 CHAR),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;