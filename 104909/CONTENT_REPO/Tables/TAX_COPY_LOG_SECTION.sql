CREATE TABLE content_repo.tax_copy_log_section (
  section_id NUMBER NOT NULL,
  section_descr VARCHAR2(32 CHAR),
  PRIMARY KEY (section_id) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;