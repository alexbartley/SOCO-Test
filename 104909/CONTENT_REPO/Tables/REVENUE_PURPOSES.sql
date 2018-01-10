CREATE TABLE content_repo.revenue_purposes (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(50 CHAR) NOT NULL,
  description VARCHAR2(250 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT revenue_purposes_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;