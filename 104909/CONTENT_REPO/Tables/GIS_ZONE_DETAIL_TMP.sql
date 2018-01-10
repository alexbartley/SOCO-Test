CREATE TABLE content_repo.gis_zone_detail_tmp (
  state_code VARCHAR2(2 CHAR),
  state_name VARCHAR2(64 CHAR),
  county_name VARCHAR2(64 CHAR),
  city_name VARCHAR2(122 CHAR),
  zip VARCHAR2(5 CHAR),
  zip9 VARCHAR2(10 CHAR),
  zip4 VARCHAR2(4 CHAR),
  default_flag VARCHAR2(1 CHAR),
  code_fips VARCHAR2(25 CHAR),
  geo_area VARCHAR2(15 CHAR),
  unique_area VARCHAR2(1000 CHAR),
  rid NUMBER
) 
TABLESPACE content_repo;