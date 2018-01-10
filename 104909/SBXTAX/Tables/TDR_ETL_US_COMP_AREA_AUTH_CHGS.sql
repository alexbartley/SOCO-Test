CREATE TABLE sbxtax.tdr_etl_us_comp_area_auth_chgs (
  "ID" NUMBER,
  area_uuid VARCHAR2(100 CHAR),
  authority_name VARCHAR2(100 CHAR),
  authority_id NUMBER,
  source_db VARCHAR2(100 CHAR),
  change_type VARCHAR2(20 CHAR)
) 
TABLESPACE ositax;