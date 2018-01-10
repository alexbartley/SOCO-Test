CREATE TABLE content_repo.location_hierarchies (
  "ID" NUMBER NOT NULL,
  location_category_id NUMBER NOT NULL,
  hierarchy_definition_id NUMBER NOT NULL,
  h_level NUMBER(2) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT location_hierarchies_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT location_hierarchies_f1 FOREIGN KEY (location_category_id) REFERENCES content_repo.location_categories ("ID"),
  CONSTRAINT location_hierarchies_f2 FOREIGN KEY (hierarchy_definition_id) REFERENCES content_repo.hierarchy_definitions ("ID")
) 
TABLESPACE content_repo;