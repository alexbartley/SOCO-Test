CREATE TABLE content_repo.tax_geo_areas (
  "ID" NUMBER NOT NULL,
  juris_tax_imposition_id NUMBER NOT NULL,
  geo_polygon_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  rid NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT tax_locations_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_locations_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;