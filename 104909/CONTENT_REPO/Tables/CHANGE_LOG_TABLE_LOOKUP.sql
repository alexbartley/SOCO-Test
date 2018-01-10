CREATE TABLE content_repo.change_log_table_lookup (
  entity NUMBER NOT NULL,
  vld_table VARCHAR2(32 CHAR),
  log_table VARCHAR2(32 CHAR),
  index_column VARCHAR2(32 CHAR)
) 
TABLESPACE content_repo;