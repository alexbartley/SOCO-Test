CREATE TABLE content_repo.admin_geo_areas (
  "ID" NUMBER NOT NULL,
  administrator_id NUMBER NOT NULL,
  geo_polygon_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  requires_registration NUMBER(1) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  rid NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  administrator_nkid NUMBER NOT NULL,
  geo_polygon_nkid NUMBER NOT NULL,
  CONSTRAINT admin_geo_areas_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT admin_geo_areas_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT admin_geo_areas_f2 FOREIGN KEY (administrator_id) REFERENCES content_repo.administrators ("ID"),
  CONSTRAINT admin_geo_areas_f3 FOREIGN KEY (geo_polygon_id) REFERENCES content_repo.geo_polygons ("ID"),
  CONSTRAINT admin_geo_areas_f5 FOREIGN KEY (rid) REFERENCES content_repo.geo_poly_ref_revisions ("ID")
) 
TABLESPACE content_repo;