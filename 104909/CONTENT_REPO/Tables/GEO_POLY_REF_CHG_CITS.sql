CREATE TABLE content_repo.geo_poly_ref_chg_cits (
  "ID" NUMBER NOT NULL,
  geo_poly_ref_chg_log_id NUMBER NOT NULL,
  citation_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT geo_poly_ref_chg_cits_pk PRIMARY KEY ("ID") USING INDEX (CREATE UNIQUE INDEX content_repo.geo_poly_ref_chg_cits_id_idx ON content_repo.geo_poly_ref_chg_cits("ID")
    
    TABLESPACE content_repo),
  CONSTRAINT geo_poly_ref_chg_cits_f1 FOREIGN KEY (citation_id) REFERENCES content_repo.citations ("ID"),
  CONSTRAINT geo_poly_ref_chg_cits_f2 FOREIGN KEY (geo_poly_ref_chg_log_id) REFERENCES content_repo.geo_poly_ref_chg_logs ("ID")
) 
TABLESPACE content_repo;