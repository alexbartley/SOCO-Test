CREATE TABLE sbxtax.pvw_tb_rate_tiers (
  authority_uuid VARCHAR2(36 CHAR),
  rate_code VARCHAR2(50 CHAR),
  start_date DATE,
  amount_low NUMBER,
  amount_high NUMBER,
  rate NUMBER,
  ref_rate_code VARCHAR2(50 CHAR),
  flat_fee NUMBER,
  is_local VARCHAR2(1 CHAR)
) 
TABLESPACE ositax;