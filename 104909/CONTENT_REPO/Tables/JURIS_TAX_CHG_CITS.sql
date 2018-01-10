CREATE TABLE content_repo.juris_tax_chg_cits (
  "ID" NUMBER NOT NULL,
  juris_tax_chg_log_id NUMBER NOT NULL,
  citation_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT juris_tax_chg_cits_pk PRIMARY KEY ("ID") USING INDEX (CREATE UNIQUE INDEX content_repo.juris_tax_chg_cits_id_idx ON content_repo.juris_tax_chg_cits("ID")
    
    TABLESPACE content_repo),
  CONSTRAINT juris_tax_chg_cits_f2 FOREIGN KEY (juris_tax_chg_log_id) REFERENCES content_repo.juris_tax_chg_logs ("ID") ON DELETE CASCADE,
  CONSTRAINT juris_tax_chg_cits_f4 FOREIGN KEY (citation_id) REFERENCES content_repo.citations ("ID")
) 
TABLESPACE content_repo;