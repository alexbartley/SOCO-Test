CREATE TABLE content_repo.assignment_types (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(50 CHAR) NOT NULL,
  description VARCHAR2(250 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date DATE NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date DATE NOT NULL,
  ui_order NUMBER NOT NULL,
  CONSTRAINT assignment_types_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;