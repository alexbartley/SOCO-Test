CREATE TABLE content_repo.geo_area_categories (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  ui_order NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT geo_area_categories_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;