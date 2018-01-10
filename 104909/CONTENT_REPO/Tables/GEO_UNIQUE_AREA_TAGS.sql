CREATE TABLE content_repo.geo_unique_area_tags (
  "ID" NUMBER NOT NULL,
  ref_nkid NUMBER NOT NULL,
  tag_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT geo_unique_area_tags_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT geo_unique_area_tags_f1 FOREIGN KEY (tag_id) REFERENCES content_repo.tags ("ID")
) 
TABLESPACE content_repo;