CREATE TABLE content_repo.ref_value_types (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(64 CHAR) NOT NULL,
  "SOURCE" VARCHAR2(64 CHAR),
  CONSTRAINT ref_value_types_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT ref_value_types__un UNIQUE ("NAME") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;