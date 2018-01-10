CREATE TABLE sbxtax.tdr_etl_us_comp_area_changes (
  "ID" NUMBER,
  "NAME" VARCHAR2(500 CHAR),
  area_uuid VARCHAR2(100 CHAR),
  eff_zone_level_id NUMBER,
  area_count NUMBER,
  start_date DATE,
  end_date DATE,
  source_db VARCHAR2(100 CHAR),
  change_type VARCHAR2(20 CHAR),
  state_code VARCHAR2(2 CHAR)
) 
TABLESPACE ositax;