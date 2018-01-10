CREATE UNIQUE INDEX sbxtax.exch_rates_u2 ON sbxtax.tb_exchange_rates(exchange_rate_source_id,from_currency_id,to_currency_id,start_date)

TABLESPACE ositax;