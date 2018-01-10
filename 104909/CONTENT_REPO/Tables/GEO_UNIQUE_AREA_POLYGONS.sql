CREATE TABLE content_repo.geo_unique_area_polygons (
  "ID" NUMBER NOT NULL,
  geo_polygon_id NUMBER,
  unique_area_id NUMBER,
  entered_date TIMESTAMP,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP
) 
TABLESPACE content_repo;