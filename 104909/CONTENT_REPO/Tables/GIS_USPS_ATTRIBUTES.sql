CREATE TABLE content_repo.gis_usps_attributes (
  "ID" NUMBER NOT NULL,
  geo_polygon_usps_id NUMBER NOT NULL,
  attribute_id NUMBER NOT NULL,
  "VALUE" VARCHAR2(128 CHAR) NOT NULL,
  override_rank NUMBER NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  status NUMBER NOT NULL,
  CONSTRAINT gis_labels_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;