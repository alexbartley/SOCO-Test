CREATE TABLE content_repo.logical_qualifiers (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  qualifier_type NUMBER NOT NULL,
  CONSTRAINT logical_qualifiers_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT logical_qualifiers__un UNIQUE ("NAME") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;