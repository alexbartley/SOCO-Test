CREATE TABLE content_repo.gis_usps_temp (
  "ID" NUMBER,
  hierarchy_level_id NUMBER,
  state_code CHAR(2 CHAR),
  county_name VARCHAR2(64 CHAR),
  county_fips VARCHAR2(4 CHAR),
  city_name VARCHAR2(64 CHAR),
  city_fips VARCHAR2(8 CHAR),
  zip CHAR(5 CHAR),
  zip4 CHAR(4 CHAR),
  zip9 CHAR(9 CHAR),
  default_flag CHAR(1 CHAR),
  geo_area_key VARCHAR2(100 CHAR),
  stj_fips VARCHAR2(12 CHAR),
  area_id VARCHAR2(60 CHAR),
  usps_id NUMBER
) 
TABLESPACE content_repo;