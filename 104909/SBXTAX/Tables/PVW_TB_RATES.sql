CREATE TABLE sbxtax.pvw_tb_rates (
  authority_uuid VARCHAR2(36 CHAR),
  rate_code VARCHAR2(50 CHAR),
  start_date DATE,
  end_date DATE,
  rate NUMBER,
  split_type VARCHAR2(5 CHAR),
  split_amount_type VARCHAR2(2 CHAR),
  flat_fee NUMBER,
  currency_id NUMBER,
  description VARCHAR2(400 CHAR),
  is_local VARCHAR2(4 CHAR),
  rate_id NUMBER
) 
TABLESPACE ositax;