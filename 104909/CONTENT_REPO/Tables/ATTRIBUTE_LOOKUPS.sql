CREATE TABLE content_repo.attribute_lookups (
  "ID" NUMBER NOT NULL,
  attribute_id NUMBER NOT NULL,
  "VALUE" VARCHAR2(100 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT attribute_lookups_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT attribute_lookups_f2 FOREIGN KEY (attribute_id) REFERENCES content_repo.additional_attributes ("ID")
) 
TABLESPACE content_repo;