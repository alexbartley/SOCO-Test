CREATE TABLE content_repo.gis_zone_auth_stage_tmp (
  state_code VARCHAR2(2 CHAR),
  state_name VARCHAR2(50 CHAR),
  county_name VARCHAR2(50 CHAR),
  city_name VARCHAR2(50 CHAR),
  zip VARCHAR2(5 CHAR),
  official_name VARCHAR2(250 CHAR),
  geo_area VARCHAR2(10 CHAR),
  unique_area VARCHAR2(1000 CHAR)
) 
TABLESPACE content_repo;