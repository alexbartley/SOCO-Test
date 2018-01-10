CREATE TABLE content_repo.package_tags (
  "ID" NUMBER NOT NULL,
  package_id NUMBER NOT NULL,
  tag_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT package_tags_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT package_tags_f2 FOREIGN KEY (tag_id) REFERENCES content_repo.tags ("ID"),
  CONSTRAINT package_tags_f3 FOREIGN KEY (package_id) REFERENCES content_repo."PACKAGES" ("ID")
) 
TABLESPACE content_repo;