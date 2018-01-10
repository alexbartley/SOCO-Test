CREATE TABLE content_repo.gis_zone_areas_tmp (
  unique_area_id NUMBER,
  unique_area_rid NUMBER,
  unique_area_nkid NUMBER,
  official_name VARCHAR2(250 CHAR),
  jurisdiction_id NUMBER,
  unique_area VARCHAR2(1000 CHAR),
  state_code VARCHAR2(2 CHAR),
  jurisdiction_nkid NUMBER,
  effective_level VARCHAR2(15 CHAR)
) 
TABLESPACE content_repo;