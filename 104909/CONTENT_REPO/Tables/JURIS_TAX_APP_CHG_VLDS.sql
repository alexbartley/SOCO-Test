CREATE TABLE content_repo.juris_tax_app_chg_vlds (
  "ID" NUMBER NOT NULL,
  assigned_user_id NUMBER NOT NULL,
  assignment_date DATE NOT NULL,
  signoff_date DATE,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  juris_tax_app_chg_log_id NUMBER NOT NULL,
  assignment_type_id NUMBER NOT NULL,
  assigned_by NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  CONSTRAINT juris_tax_app_chg_vlds_f1 FOREIGN KEY (assignment_type_id) REFERENCES content_repo.assignment_types ("ID")
) TABLESPACE content_repo
PARTITION BY HASH ("ID")
(PARTITION
  INDEXING ON
  TABLESPACE juris_tax_app_chg,
PARTITION
  INDEXING ON
  TABLESPACE juris_tax_app_chg,
PARTITION
  INDEXING ON
  TABLESPACE juris_tax_app_chg,
PARTITION
  INDEXING ON
  TABLESPACE juris_tax_app_chg,
PARTITION
  INDEXING ON
  TABLESPACE juris_tax_app_chg,
PARTITION
  INDEXING ON
  TABLESPACE juris_tax_app_chg);