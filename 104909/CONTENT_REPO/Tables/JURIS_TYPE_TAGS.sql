CREATE TABLE content_repo.juris_type_tags (
  "ID" NUMBER NOT NULL,
  ref_nkid NUMBER NOT NULL,
  tag_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  first_etl_rid NUMBER,
  last_etl_rid NUMBER,
  CONSTRAINT juris_type_tags_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT juris_type_tags_f1 FOREIGN KEY (tag_id) REFERENCES content_repo.tags ("ID")
) 
TABLESPACE content_repo;