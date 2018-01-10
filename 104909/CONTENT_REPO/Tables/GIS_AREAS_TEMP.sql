CREATE TABLE content_repo.gis_areas_temp (
  "ID" NUMBER,
  official_name VARCHAR2(250 CHAR),
  rid NUMBER,
  nkid NUMBER,
  geo_area VARCHAR2(50 CHAR),
  next_level VARCHAR2(50 CHAR),
  county VARCHAR2(64 CHAR),
  city VARCHAR2(64 CHAR),
  district VARCHAR2(50 CHAR),
  short_name VARCHAR2(250 CHAR),
  alt_name VARCHAR2(250 CHAR)
) 
TABLESPACE content_repo;