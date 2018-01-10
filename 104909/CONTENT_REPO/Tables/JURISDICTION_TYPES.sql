CREATE TABLE content_repo.jurisdiction_types (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(100 BYTE),
  description VARCHAR2(1000 BYTE),
  nkid NUMBER,
  rid NUMBER,
  next_rid NUMBER,
  status NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP,
  start_date DATE,
  end_date DATE,
  full_name VARCHAR2(110 BYTE),
  CONSTRAINT jurisdiction_types_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT jurisdiction_type_f1 FOREIGN KEY (rid,nkid) REFERENCES content_repo.jurisdiction_type_revisions ("ID",nkid)
) 
TABLESPACE content_repo;