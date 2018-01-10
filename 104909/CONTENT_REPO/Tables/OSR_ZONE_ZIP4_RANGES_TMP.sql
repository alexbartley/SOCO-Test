CREATE TABLE content_repo.osr_zone_zip4_ranges_tmp (
  state_code VARCHAR2(2 CHAR),
  zip VARCHAR2(5 CHAR),
  zip4_range VARCHAR2(15 CHAR),
  default_flag VARCHAR2(1 CHAR),
  rec_type VARCHAR2(1 CHAR),
  range_min VARCHAR2(4 CHAR),
  range_max VARCHAR2(4 CHAR),
  area_id VARCHAR2(60 CHAR),
  county_name VARCHAR2(64 CHAR),
  city_name VARCHAR2(64 CHAR)
) 
TABLESPACE content_repo;