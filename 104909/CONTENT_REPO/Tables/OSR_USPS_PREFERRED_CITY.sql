CREATE TABLE content_repo.osr_usps_preferred_city (
  state_code VARCHAR2(2 CHAR),
  zip VARCHAR2(5 CHAR),
  county_name VARCHAR2(64 CHAR),
  city_name VARCHAR2(64 CHAR),
  area_id VARCHAR2(60 CHAR)
) 
TABLESPACE content_repo;