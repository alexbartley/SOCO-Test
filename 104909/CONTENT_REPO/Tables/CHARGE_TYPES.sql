CREATE TABLE content_repo.charge_types (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  abbreviation VARCHAR2(2 CHAR),
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status NUMBER(1) NOT NULL,
  status_modified_date TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT charge_types_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;