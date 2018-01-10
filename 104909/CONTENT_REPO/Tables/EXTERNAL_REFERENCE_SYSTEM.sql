CREATE TABLE content_repo.external_reference_system (
  "ID" NUMBER NOT NULL,
  system_name VARCHAR2(32 CHAR) NOT NULL,
  system_descr VARCHAR2(64 CHAR),
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP WITH TIME ZONE,
  status NUMBER NOT NULL,
  status_modified_date TIMESTAMP WITH TIME ZONE,
  PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;