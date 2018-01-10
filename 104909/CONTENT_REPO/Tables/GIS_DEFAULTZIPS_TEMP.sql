CREATE TABLE content_repo.gis_defaultzips_temp (
  geo_polygon_id NUMBER,
  geo_area_key VARCHAR2(100 CHAR),
  state_name VARCHAR2(50 CHAR),
  state_code VARCHAR2(2 CHAR),
  state_fips VARCHAR2(4 CHAR),
  county_name VARCHAR2(64 CHAR),
  county_fips VARCHAR2(4 CHAR),
  city_name VARCHAR2(64 CHAR),
  city_fips VARCHAR2(8 CHAR),
  zip9 VARCHAR2(9 CHAR),
  zipcode VARCHAR2(5 CHAR),
  zip4 VARCHAR2(4 CHAR),
  default_zip4 CHAR(1 CHAR),
  city_rank NUMBER(2),
  multiple_cities NUMBER(2),
  hierarchy_level_id NUMBER,
  stjname VARCHAR2(500 CHAR),
  area_id VARCHAR2(60 CHAR)
) 
TABLESPACE content_repo;