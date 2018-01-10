CREATE TABLE content_repo.additional_attributes (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  attribute_category_id NUMBER NOT NULL,
  purpose VARCHAR2(1000 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  CONSTRAINT additional_attributes_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT additional_attributes_f2 FOREIGN KEY (attribute_category_id) REFERENCES content_repo.attribute_categories ("ID")
) 
TABLESPACE content_repo;