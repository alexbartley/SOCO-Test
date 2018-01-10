CREATE TABLE content_repo.gis_mapped_areas_temp (
  jurisdiction_id NUMBER,
  geo_polygon_id NUMBER,
  start_date VARCHAR2(12 CHAR),
  end_date VARCHAR2(12 CHAR),
  rid NUMBER,
  nkid NUMBER,
  unique_area_id NUMBER
) 
TABLESPACE content_repo;