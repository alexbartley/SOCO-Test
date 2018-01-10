CREATE TABLE content_repo.comm_chg_logs (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  entity_id NUMBER NOT NULL,
  reason_id NUMBER,
  "SUMMARY" VARCHAR2(500 CHAR),
  table_name VARCHAR2(30 CHAR),
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  primary_key NUMBER NOT NULL,
  CONSTRAINT comm_chg_logs_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT comm_chg_logs_f1 FOREIGN KEY (reason_id) REFERENCES content_repo.change_reasons ("ID"),
  CONSTRAINT comm_chg_logs_f2 FOREIGN KEY (rid) REFERENCES content_repo.commodity_revisions ("ID")
) 
TABLESPACE content_repo;