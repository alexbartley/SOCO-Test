CREATE TABLE content_repo.geo_unique_area_attributes (
  "ID" NUMBER NOT NULL,
  geo_unique_area_id NUMBER NOT NULL,
  attribute_id NUMBER NOT NULL,
  "VALUE" VARCHAR2(128 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  CONSTRAINT geo_unique_area_attribute_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT geo_unique_area_attr_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT geo_unique_areas_f1 FOREIGN KEY (geo_unique_area_id) REFERENCES content_repo.geo_unique_areas ("ID")
) 
TABLESPACE content_repo;