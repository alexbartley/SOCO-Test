CREATE UNIQUE INDEX sbxtax.tdr_etl_tb_comp_areas_u1 ON sbxtax.tdr_etl_tb_compliance_areas(compliance_area_uuid,"NAME",start_date)
TABLESPACE ositax;