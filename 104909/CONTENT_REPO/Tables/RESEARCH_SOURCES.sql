CREATE TABLE content_repo.research_sources (
  "ID" NUMBER NOT NULL,
  description VARCHAR2(1000 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT -2 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  next_contact_date DATE,
  frequency VARCHAR2(64 CHAR),
  "OWNER" NUMBER,
  start_date DATE,
  end_date DATE,
  CONSTRAINT research_sources_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;