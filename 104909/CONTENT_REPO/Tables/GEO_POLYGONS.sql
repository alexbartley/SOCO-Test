CREATE TABLE content_repo.geo_polygons (
  "ID" NUMBER NOT NULL,
  hierarchy_level_id NUMBER NOT NULL,
  geo_area_key VARCHAR2(100 CHAR) NOT NULL,
  geo_polygon_type_id NUMBER NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  "VIRTUAL" NUMBER(1),
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  CONSTRAINT geo_polygons_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT geo_polygons_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT geo_polygons_f2 FOREIGN KEY (geo_polygon_type_id) REFERENCES content_repo.geo_polygon_types ("ID"),
  CONSTRAINT geo_polygons_f4 FOREIGN KEY (hierarchy_level_id) REFERENCES content_repo.hierarchy_levels ("ID")
) 
TABLESPACE content_repo;