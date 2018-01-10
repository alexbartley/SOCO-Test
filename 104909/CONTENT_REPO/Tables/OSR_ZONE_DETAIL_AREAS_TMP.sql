CREATE TABLE content_repo.osr_zone_detail_areas_tmp (
  state_code VARCHAR2(2 CHAR),
  county_name VARCHAR2(64 CHAR),
  city_name VARCHAR2(122 CHAR),
  zip VARCHAR2(5 CHAR),
  zip9 VARCHAR2(10 CHAR),
  unique_area VARCHAR2(500 CHAR),
  area_id VARCHAR2(60 CHAR)
) 
TABLESPACE content_repo;