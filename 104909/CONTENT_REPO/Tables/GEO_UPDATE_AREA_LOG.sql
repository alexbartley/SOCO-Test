CREATE TABLE content_repo.geo_update_area_log (
  "ID" NUMBER NOT NULL,
  state_code VARCHAR2(2 CHAR),
  unique_area VARCHAR2(1000 CHAR),
  update_type VARCHAR2(10 CHAR),
  entered_by NUMBER,
  entered_date TIMESTAMP,
  status NUMBER,
  status_modified_date TIMESTAMP,
  area_id VARCHAR2(60 CHAR),
  CONSTRAINT geo_update_area_log_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;