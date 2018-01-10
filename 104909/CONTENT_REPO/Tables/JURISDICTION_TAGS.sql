CREATE TABLE content_repo.jurisdiction_tags (
  "ID" NUMBER NOT NULL,
  ref_nkid NUMBER NOT NULL,
  tag_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  first_etl_id NUMBER,
  last_etl_id NUMBER,
  CONSTRAINT jurisdiction_tags_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT jurisdiction_tags_f1 FOREIGN KEY (tag_id) REFERENCES content_repo.tags ("ID")
) 
TABLESPACE content_repo;