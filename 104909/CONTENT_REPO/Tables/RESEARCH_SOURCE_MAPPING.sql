CREATE TABLE content_repo.research_source_mapping (
  "ID" NUMBER NOT NULL,
  research_source_id NUMBER NOT NULL,
  table_name VARCHAR2(50 CHAR) NOT NULL,
  ref_nkid NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  CONSTRAINT research_source_mapping_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT research_source_mapping_f1 FOREIGN KEY (research_source_id) REFERENCES content_repo.research_sources ("ID")
) 
TABLESPACE content_repo;