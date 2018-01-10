CREATE TABLE content_repo.jurisdiction_revisions (
  "ID" NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  next_rid NUMBER,
  summ_ass_status NUMBER DEFAULT 0,
  ready_for_staging NUMBER(1),
  CONSTRAINT jurisdiction_revisions_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT jurisdiction_revisions__un UNIQUE ("ID",nkid) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;