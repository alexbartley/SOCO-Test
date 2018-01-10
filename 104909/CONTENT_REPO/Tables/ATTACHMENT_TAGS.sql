CREATE TABLE content_repo.attachment_tags (
  "ID" NUMBER NOT NULL,
  attachment_id NUMBER NOT NULL,
  tag_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT attachment_tags_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT attachment_tags_f1 FOREIGN KEY (tag_id) REFERENCES content_repo.tags ("ID"),
  CONSTRAINT attachment_tags_f2 FOREIGN KEY (attachment_id) REFERENCES content_repo.attachments ("ID")
) 
TABLESPACE content_repo;