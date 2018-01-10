CREATE TABLE content_repo.taxability_elements (
  "ID" NUMBER NOT NULL,
  element_name VARCHAR2(100 CHAR) NOT NULL,
  description VARCHAR2(1000 CHAR),
  element_value_type VARCHAR2(20 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT applicability_elements_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;