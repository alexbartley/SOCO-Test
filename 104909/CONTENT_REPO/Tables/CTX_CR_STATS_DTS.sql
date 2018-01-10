CREATE TABLE content_repo.ctx_cr_stats_dts (
  dts_id NUMBER NOT NULL,
  dts_name VARCHAR2(32 CHAR),
  raw_table VARCHAR2(32 CHAR),
  PRIMARY KEY (dts_id) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;