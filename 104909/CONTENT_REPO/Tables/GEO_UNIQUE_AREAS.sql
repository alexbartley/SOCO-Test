CREATE TABLE content_repo.geo_unique_areas (
  "ID" NUMBER NOT NULL,
  area_id VARCHAR2(60 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_date TIMESTAMP,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  CONSTRAINT geo_unique_areas_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT geo_unique_areas_un UNIQUE (area_id) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT geo_unique_areas_un1 UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;