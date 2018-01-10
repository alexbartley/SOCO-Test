CREATE TABLE content_repo.reference_groups (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(250 CHAR) NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  rid NUMBER NOT NULL,
  next_rid NUMBER,
  nkid NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  description VARCHAR2(1000 CHAR),
  CONSTRAINT reference_groups_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;