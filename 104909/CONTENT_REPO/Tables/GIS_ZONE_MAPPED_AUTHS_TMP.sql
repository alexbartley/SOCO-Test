CREATE TABLE content_repo.gis_zone_mapped_auths_tmp (
  state_code VARCHAR2(2 CHAR),
  official_name VARCHAR2(250 CHAR),
  jurisdiction_id NUMBER,
  jurisdiction_nkid NUMBER,
  rid NUMBER,
  nkid NUMBER,
  geo_polygon_rid NUMBER
) 
TABLESPACE content_repo;