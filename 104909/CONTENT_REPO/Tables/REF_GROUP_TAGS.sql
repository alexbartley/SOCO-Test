CREATE TABLE content_repo.ref_group_tags (
  "ID" NUMBER NOT NULL,
  ref_nkid NUMBER NOT NULL,
  tag_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT ref_group_tags_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT ref_group_tags_f1 FOREIGN KEY (tag_id) REFERENCES content_repo.tags ("ID")
) 
TABLESPACE content_repo;