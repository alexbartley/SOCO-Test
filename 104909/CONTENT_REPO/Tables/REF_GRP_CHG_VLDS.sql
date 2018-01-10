CREATE TABLE content_repo.ref_grp_chg_vlds (
  "ID" NUMBER NOT NULL,
  assigned_user_id NUMBER NOT NULL,
  assignment_date DATE NOT NULL,
  signoff_date DATE,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  ref_grp_chg_log_id NUMBER NOT NULL,
  assignment_type_id NUMBER NOT NULL,
  assigned_by NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  CONSTRAINT ref_group_chg_vlds_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT ref_group_chg_vlds_f2 FOREIGN KEY (ref_grp_chg_log_id) REFERENCES content_repo.ref_grp_chg_logs ("ID"),
  CONSTRAINT ref_grp_chg_vlds_f1 FOREIGN KEY (assignment_type_id) REFERENCES content_repo.assignment_types ("ID")
) 
TABLESPACE content_repo;