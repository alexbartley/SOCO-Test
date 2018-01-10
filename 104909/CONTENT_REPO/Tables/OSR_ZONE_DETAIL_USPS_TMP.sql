CREATE TABLE content_repo.osr_zone_detail_usps_tmp (
  state_code VARCHAR2(2 CHAR),
  state_name VARCHAR2(64 CHAR),
  county_name VARCHAR2(64 CHAR),
  city_name VARCHAR2(122 CHAR),
  zip VARCHAR2(5 CHAR),
  zip4 VARCHAR2(4 CHAR),
  zip9 VARCHAR2(10 CHAR),
  default_flag VARCHAR2(1 CHAR),
  area_id VARCHAR2(60 CHAR),
  geo_polygon_id NUMBER
) 
TABLESPACE content_repo;