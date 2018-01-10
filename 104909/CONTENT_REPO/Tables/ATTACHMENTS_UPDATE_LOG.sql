CREATE TABLE content_repo.attachments_update_log (
  entity NUMBER,
  last_updated DATE,
  table_name VARCHAR2(30 CHAR),
  entered_by NUMBER,
  chg_cit_id NUMBER,
  attachment_id NUMBER
) 
TABLESPACE content_repo;
COMMENT ON TABLE content_repo.attachments_update_log IS 'Log for updated citations aka delete documents';