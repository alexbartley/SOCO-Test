CREATE TABLE content_repo.update_multiple_sections (
  "ID" NUMBER NOT NULL CONSTRAINT update_multiple_sections_pk CHECK ("ID" IS NOT NULL),
  description VARCHAR2(64 CHAR),
  UNIQUE ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;