CREATE TABLE content_repo.geo_poly_ref_chg_logs (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  table_name VARCHAR2(50 CHAR) NOT NULL,
  primary_key NUMBER NOT NULL,
  entity_id NUMBER NOT NULL,
  reason_id NUMBER,
  "SUMMARY" VARCHAR2(1000 CHAR),
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT geo_poly_ref_chg_logs_pk PRIMARY KEY ("ID") USING INDEX (CREATE UNIQUE INDEX content_repo.geo_poly_ref_chg_logs_u1 ON content_repo.geo_poly_ref_chg_logs("ID")
    
    TABLESPACE content_repo),
  CONSTRAINT geo_poly_ref_chg_logs_f1 FOREIGN KEY (reason_id) REFERENCES content_repo.change_reasons ("ID"),
  CONSTRAINT geo_poly_ref_chg_logs_f2 FOREIGN KEY (rid) REFERENCES content_repo.geo_poly_ref_revisions ("ID")
) 
TABLESPACE content_repo;