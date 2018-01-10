CREATE TABLE content_repo.tags (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(50 CHAR) NOT NULL,
  tag_type_id NUMBER NOT NULL,
  entered_by NUMBER(38) NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT tags_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tags_f2 FOREIGN KEY (tag_type_id) REFERENCES content_repo.tag_types ("ID")
) 
TABLESPACE content_repo;