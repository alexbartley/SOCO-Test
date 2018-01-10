CREATE TABLE content_repo.ref_grp_chg_cits (
  "ID" NUMBER NOT NULL,
  ref_grp_chg_log_id NUMBER NOT NULL,
  citation_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT ref_group_chg_cits_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT ref_group_chg_cits_f2 FOREIGN KEY (ref_grp_chg_log_id) REFERENCES content_repo.ref_grp_chg_logs ("ID"),
  CONSTRAINT ref_group_chg_cits_f4 FOREIGN KEY (citation_id) REFERENCES content_repo.citations ("ID")
) 
TABLESPACE content_repo;