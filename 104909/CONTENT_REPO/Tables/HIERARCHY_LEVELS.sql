CREATE TABLE content_repo.hierarchy_levels (
  "ID" NUMBER NOT NULL,
  geo_area_category_id NUMBER NOT NULL,
  hierarchy_definition_id NUMBER NOT NULL,
  h_level NUMBER(2) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT hierarchy_levels_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT hierarchy_levels_f1 FOREIGN KEY (geo_area_category_id) REFERENCES content_repo.geo_area_categories ("ID"),
  CONSTRAINT hierarchy_levels_f2 FOREIGN KEY (hierarchy_definition_id) REFERENCES content_repo.hierarchy_definitions ("ID")
) 
TABLESPACE content_repo;