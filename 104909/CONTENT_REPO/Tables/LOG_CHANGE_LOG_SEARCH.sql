CREATE TABLE content_repo.log_change_log_search (
  sdate DATE,
  entity VARCHAR2(32 CHAR),
  search_modifby VARCHAR2(32 CHAR),
  search_reason VARCHAR2(32 CHAR),
  search_doc VARCHAR2(32 CHAR),
  search_verif VARCHAR2(32 CHAR),
  search_data VARCHAR2(32 CHAR),
  search_tags VARCHAR2(32 CHAR),
  modifafter VARCHAR2(32 CHAR),
  modifbefore VARCHAR2(32 CHAR)
) 
TABLESPACE content_repo;
COMMENT ON TABLE content_repo.log_change_log_search IS 'Debug table for change log search';