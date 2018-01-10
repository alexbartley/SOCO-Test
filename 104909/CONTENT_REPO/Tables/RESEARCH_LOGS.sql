CREATE TABLE content_repo.research_logs (
  "ID" NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  note VARCHAR2(1000 CHAR) NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT -2 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  source_contact_id NUMBER NOT NULL,
  CONSTRAINT research_logs_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;