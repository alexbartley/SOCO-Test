CREATE UNIQUE INDEX sbxtax.tb_loctaxcat_u2 ON sbxtax.tb_location_tax_categories("NAME",start_date,merchant_id)

TABLESPACE ositax;