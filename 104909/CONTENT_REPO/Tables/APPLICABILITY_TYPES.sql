CREATE TABLE content_repo.applicability_types (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status NUMBER(*,0) DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP WITH TIME ZONE NOT NULL,
  abbreviation VARCHAR2(2 BYTE),
  CONSTRAINT applicability_types_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;