CREATE TABLE content_repo.gis_zone_juris_areas_tmp (
  state_code VARCHAR2(2 CHAR),
  unique_area_id NUMBER,
  unique_area VARCHAR2(1000 CHAR),
  hierarchy_level NUMBER,
  geo_area VARCHAR2(25 CHAR)
) 
TABLESPACE content_repo;