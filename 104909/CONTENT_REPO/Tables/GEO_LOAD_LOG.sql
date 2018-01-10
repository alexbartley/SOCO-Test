CREATE TABLE content_repo.geo_load_log (
  "ID" NUMBER NOT NULL,
  state_code VARCHAR2(2 CHAR) NOT NULL,
  start_time TIMESTAMP NOT NULL,
  stop_time TIMESTAMP,
  initial_count NUMBER DEFAULT 0 NOT NULL,
  failure_count NUMBER DEFAULT 0 NOT NULL,
  success_count NUMBER DEFAULT 0 NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  polygon_stop_time TIMESTAMP,
  extract_stop_time TIMESTAMP,
  ranking_stop_time TIMESTAMP,
  usps_stop_time TIMESTAMP,
  areas_stop_time TIMESTAMP,
  import_type CHAR(1 CHAR),
  job_id NUMBER,
  CONSTRAINT geo_load_log_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;