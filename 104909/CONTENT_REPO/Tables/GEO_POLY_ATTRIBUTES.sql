CREATE TABLE content_repo.geo_poly_attributes (
  "ID" NUMBER NOT NULL,
  geo_polygon_id NUMBER NOT NULL,
  attribute_id NUMBER NOT NULL,
  "VALUE" VARCHAR2(500 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  geo_polygon_nkid NUMBER NOT NULL,
  CONSTRAINT geo_poly_attributes_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT geo_poly_attributes_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT geo_poly_attributes_f3 FOREIGN KEY (geo_polygon_id) REFERENCES content_repo.geo_polygons ("ID"),
  CONSTRAINT location_attribute_values_f3 FOREIGN KEY (attribute_id) REFERENCES content_repo.additional_attributes ("ID")
) 
TABLESPACE content_repo;