CREATE TABLE sbxtax.tmp_tb_rate_tiers_01_19 (
  rate_code VARCHAR2(20 CHAR),
  amount_low NUMBER,
  amount_high NUMBER,
  rate NUMBER,
  ref_rate_code VARCHAR2(20 CHAR),
  flat_fee NUMBER,
  start_date DATE,
  authority_uuid VARCHAR2(36 CHAR),
  is_local VARCHAR2(1 CHAR),
  nkid NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;