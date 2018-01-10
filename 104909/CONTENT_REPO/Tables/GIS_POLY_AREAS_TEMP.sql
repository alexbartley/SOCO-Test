CREATE TABLE content_repo.gis_poly_areas_temp (
  "ID" NUMBER,
  geo_area_key VARCHAR2(100 CHAR),
  geo_area VARCHAR2(25 CHAR),
  state_code VARCHAR2(2 CHAR),
  state_name VARCHAR2(50 CHAR),
  start_date VARCHAR2(12 CHAR),
  end_date VARCHAR2(12 CHAR),
  official_name VARCHAR2(250 CHAR),
  county_name VARCHAR2(64 CHAR),
  city_name VARCHAR2(64 CHAR),
  unique_area VARCHAR2(1000 CHAR),
  unique_area_id NUMBER,
  rid NUMBER,
  nkid NUMBER,
  entered_by NUMBER,
  status NUMBER,
  zip VARCHAR2(5 CHAR),
  zip9 VARCHAR2(12 CHAR),
  area_id VARCHAR2(60 CHAR)
) 
TABLESPACE content_repo;