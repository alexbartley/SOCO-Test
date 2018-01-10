CREATE TABLE sbxtax.tmp_tb_rates_0117 (
  rate_code VARCHAR2(20 CHAR),
  start_date DATE,
  end_date DATE,
  rate NUMBER(*,6),
  split_type VARCHAR2(5 CHAR),
  split_amount_type VARCHAR2(5 CHAR),
  flat_fee NUMBER,
  currency_id NUMBER,
  authority_uuid VARCHAR2(36 CHAR),
  description VARCHAR2(400 CHAR),
  is_local VARCHAR2(4 CHAR),
  rate_id NUMBER,
  unit_of_measure_code VARCHAR2(64 CHAR),
  nkid NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;