CREATE TABLE content_repo.gis_etl_process_log (
  process_id NUMBER NOT NULL,
  state_code CHAR(2 CHAR),
  etl_process VARCHAR2(250 CHAR),
  start_date TIMESTAMP,
  end_date TIMESTAMP,
  entered_by NUMBER
) 
TABLESPACE content_repo;