CREATE TABLE content_repo.osr_zone_area_list_tmp (
  unique_area VARCHAR2(500 CHAR),
  stj_flag NUMBER(1),
  state_name VARCHAR2(50 CHAR),
  county_name VARCHAR2(50 CHAR),
  city_name VARCHAR2(50 CHAR),
  zip VARCHAR2(5 CHAR),
  zip4 VARCHAR2(4 CHAR),
  default_flag CHAR(1 CHAR),
  code_fips VARCHAR2(25 CHAR),
  state_code VARCHAR2(2 CHAR),
  jurisdiction_id NUMBER,
  official_name VARCHAR2(250 CHAR),
  rid NUMBER,
  nkid NUMBER,
  geo_area VARCHAR2(25 CHAR),
  geoarea_updated NUMBER(1),
  area_id VARCHAR2(60 CHAR),
  acceptable_city VARCHAR2(1 CHAR)
) 
TABLESPACE content_repo;