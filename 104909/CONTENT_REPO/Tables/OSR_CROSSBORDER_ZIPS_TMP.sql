CREATE TABLE content_repo.osr_crossborder_zips_tmp (
  state_code VARCHAR2(2 CHAR),
  county_name VARCHAR2(50 CHAR),
  city_name VARCHAR2(50 CHAR),
  zip VARCHAR2(5 CHAR),
  override_rank NUMBER,
  area_id VARCHAR2(60 CHAR),
  zip9count NUMBER,
  zip9rank NUMBER
) 
TABLESPACE content_repo;