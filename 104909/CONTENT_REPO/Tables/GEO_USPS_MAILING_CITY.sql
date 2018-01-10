CREATE TABLE content_repo.geo_usps_mailing_city (
  state_code VARCHAR2(2 CHAR),
  zip VARCHAR2(5 CHAR),
  city_name VARCHAR2(64 CHAR),
  county_name VARCHAR2(64 CHAR),
  county_fips VARCHAR2(3 CHAR)
) 
TABLESPACE content_repo;