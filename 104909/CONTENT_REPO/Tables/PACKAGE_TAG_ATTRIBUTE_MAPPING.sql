CREATE TABLE content_repo.package_tag_attribute_mapping (
  "ID" NUMBER NOT NULL,
  package_tag_id NUMBER NOT NULL,
  table_name VARCHAR2(50 CHAR) NOT NULL,
  attribute_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  CONSTRAINT package_tag_attribute_map_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT package_tag_attribute_map_f2 FOREIGN KEY (attribute_id) REFERENCES content_repo.additional_attributes ("ID")
) 
TABLESPACE content_repo;