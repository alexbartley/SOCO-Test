CREATE TABLE content_repo.product_trees (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(64 CHAR) NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  short_name NVARCHAR2(20) NOT NULL,
  CONSTRAINT product_trees_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;