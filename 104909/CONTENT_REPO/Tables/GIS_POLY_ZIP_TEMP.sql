CREATE TABLE content_repo.gis_poly_zip_temp (
  geo_area_key VARCHAR2(100 CHAR),
  state_name VARCHAR2(50 CHAR),
  "STATE" VARCHAR2(2 CHAR),
  state_fips VARCHAR2(4 CHAR),
  county_name VARCHAR2(64 CHAR),
  county_fips VARCHAR2(4 CHAR),
  city_name VARCHAR2(64 CHAR),
  city_fips VARCHAR2(8 CHAR),
  city_startdate DATE,
  city_enddate DATE,
  stj_name VARCHAR2(100 CHAR),
  stj_fips VARCHAR2(8 CHAR),
  stj_enddate DATE,
  zip9 VARCHAR2(12 CHAR),
  zip VARCHAR2(5 CHAR),
  zip4 CHAR(4 CHAR),
  default_zip4 CHAR(1 CHAR),
  city_rank NUMBER,
  geo_poly_id NUMBER,
  area_id VARCHAR2(60 CHAR)
) 
TABLESPACE content_repo;