CREATE TABLE content_repo.administrator_types (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  description VARCHAR2(500 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  ui_order NUMBER DEFAULT 0,
  CONSTRAINT administrator_types_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT administrator_types_un UNIQUE ("NAME") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;