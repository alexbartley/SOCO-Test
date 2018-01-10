CREATE UNIQUE INDEX sbxtax.tb_rates_u2 ON sbxtax.tb_rates(merchant_id,authority_id,rate_code,start_date,is_local)

TABLESPACE ositax;