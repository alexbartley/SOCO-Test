CREATE TABLE content_repo.record_statuses (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(30 CHAR) NOT NULL,
  description VARCHAR2(250 CHAR) NOT NULL,
  CONSTRAINT record_statuses_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT sys_record_statuses__un UNIQUE ("NAME") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;