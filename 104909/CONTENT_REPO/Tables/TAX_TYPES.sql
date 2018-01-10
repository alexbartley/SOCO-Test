CREATE TABLE content_repo.tax_types (
  "ID" NUMBER NOT NULL,
  code_group VARCHAR2(16 BYTE),
  code VARCHAR2(4 BYTE),
  description VARCHAR2(100 BYTE),
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  abbreviation VARCHAR2(10 CHAR),
  CONSTRAINT tax_types_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;