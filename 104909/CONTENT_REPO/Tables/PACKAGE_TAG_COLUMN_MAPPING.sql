CREATE TABLE content_repo.package_tag_column_mapping (
  "ID" NUMBER NOT NULL,
  package_tag_id NUMBER NOT NULL,
  table_name VARCHAR2(50 CHAR) NOT NULL,
  column_name VARCHAR2(50 CHAR) NOT NULL,
  primary_key NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  CONSTRAINT package_tag_column_mapping_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;