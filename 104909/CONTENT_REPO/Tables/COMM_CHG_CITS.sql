CREATE TABLE content_repo.comm_chg_cits (
  "ID" NUMBER NOT NULL,
  comm_chg_log_id NUMBER NOT NULL,
  citation_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT comm_chg_cits_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT comm_chg_cits_f1 FOREIGN KEY (citation_id) REFERENCES content_repo.citations ("ID"),
  CONSTRAINT comm_chg_cits_f2 FOREIGN KEY (comm_chg_log_id) REFERENCES content_repo.comm_chg_logs ("ID")
) 
TABLESPACE content_repo;