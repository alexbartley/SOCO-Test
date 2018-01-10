CREATE TABLE content_repo.citations (
  "ID" NUMBER NOT NULL,
  attachment_id NUMBER NOT NULL,
  "TEXT" VARCHAR2(4000 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT citations_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT citations_f2 FOREIGN KEY (attachment_id) REFERENCES content_repo.attachments ("ID")
) 
TABLESPACE content_repo
LOB ("TEXT") STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);