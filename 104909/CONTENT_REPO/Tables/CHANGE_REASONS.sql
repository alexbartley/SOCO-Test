CREATE TABLE content_repo.change_reasons (
  "ID" NUMBER NOT NULL,
  reason VARCHAR2(100 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT change_reasons_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT change_reasons__un UNIQUE (reason) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;