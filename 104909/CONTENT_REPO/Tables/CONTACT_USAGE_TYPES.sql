CREATE TABLE content_repo.contact_usage_types (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT contact_usage_types PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;