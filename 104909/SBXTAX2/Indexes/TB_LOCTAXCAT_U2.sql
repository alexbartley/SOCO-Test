CREATE UNIQUE INDEX sbxtax2.tb_loctaxcat_u2 ON sbxtax2.tb_location_tax_categories("NAME",start_date,merchant_id)

TABLESPACE ositax;