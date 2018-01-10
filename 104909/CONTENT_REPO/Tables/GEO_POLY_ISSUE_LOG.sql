CREATE TABLE content_repo.geo_poly_issue_log (
  "ID" NUMBER NOT NULL,
  state_code VARCHAR2(2 CHAR),
  geo_area_key VARCHAR2(100 CHAR),
  geo_polygon_id NUMBER,
  rid NUMBER,
  nkid NUMBER,
  entered_by NUMBER,
  entered_date TIMESTAMP,
  issue VARCHAR2(250 CHAR),
  "ACTION" VARCHAR2(250 CHAR),
  CONSTRAINT geo_poly_issue_log_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;