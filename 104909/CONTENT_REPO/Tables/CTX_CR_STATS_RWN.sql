CREATE TABLE content_repo.ctx_cr_stats_rwn (
  rwn_id NUMBER NOT NULL,
  dts_id NUMBER NOT NULL,
  rec_count NUMBER NOT NULL,
  PRIMARY KEY (rwn_id) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT ctx_cr_stats_rwn_fkdts FOREIGN KEY (dts_id) REFERENCES content_repo.ctx_cr_stats_dts (dts_id)
) 
TABLESPACE content_repo;