CREATE TABLE content_repo.research_source_tags (
  "ID" NUMBER NOT NULL,
  research_source_id NUMBER NOT NULL,
  tag_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT research_source_tags_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT research_source_tags_f1 FOREIGN KEY (tag_id) REFERENCES content_repo.tags ("ID"),
  CONSTRAINT research_source_tags_f2 FOREIGN KEY (research_source_id) REFERENCES content_repo.research_sources ("ID")
) 
TABLESPACE content_repo;