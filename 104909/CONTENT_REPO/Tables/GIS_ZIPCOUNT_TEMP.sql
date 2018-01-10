CREATE TABLE content_repo.gis_zipcount_temp (
  "STATE" VARCHAR2(2 CHAR),
  zipcode VARCHAR2(5 CHAR),
  zip9 VARCHAR2(9 CHAR),
  countyname VARCHAR2(64 CHAR),
  cityname VARCHAR2(64 CHAR),
  stjname VARCHAR2(500 CHAR),
  zipcount NUMBER,
  geo_area_key VARCHAR2(100 CHAR),
  state_name VARCHAR2(50 CHAR),
  citycount NUMBER,
  match_id NUMBER,
  defaultzip CHAR(1 CHAR),
  hierarchy_level_id NUMBER,
  area_id VARCHAR2(60 CHAR)
) 
TABLESPACE content_repo;