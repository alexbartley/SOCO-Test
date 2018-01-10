CREATE TABLE content_repo.juris_geo_areas (
  "ID" NUMBER NOT NULL,
  jurisdiction_id NUMBER NOT NULL,
  geo_polygon_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  requires_establishment NUMBER(1) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  rid NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  geo_polygon_nkid NUMBER NOT NULL,
  jurisdiction_nkid NUMBER NOT NULL,
  CONSTRAINT juris_geo_areas_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT juris_geo_areas_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT juris_geo_areas_f3 FOREIGN KEY (jurisdiction_id) REFERENCES content_repo.jurisdictions ("ID"),
  CONSTRAINT juris_geo_areas_f4 FOREIGN KEY (geo_polygon_id) REFERENCES content_repo.geo_polygons ("ID"),
  CONSTRAINT juris_geo_areas_f5 FOREIGN KEY (rid) REFERENCES content_repo.geo_poly_ref_revisions ("ID")
) 
TABLESPACE content_repo;