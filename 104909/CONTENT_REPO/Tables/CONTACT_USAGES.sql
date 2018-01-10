CREATE TABLE content_repo.contact_usages (
  "ID" NUMBER NOT NULL,
  research_source_contact_id NUMBER NOT NULL,
  contact_usage_type_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT -2 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  usage_order NUMBER DEFAULT 0 NOT NULL,
  start_date DATE,
  end_date DATE,
  CONSTRAINT contact_usages_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT contact_usages_f3 FOREIGN KEY (research_source_contact_id) REFERENCES content_repo.research_source_contacts ("ID"),
  CONSTRAINT contact_usages_f4 FOREIGN KEY (contact_usage_type_id) REFERENCES content_repo.contact_usage_types ("ID")
) 
TABLESPACE content_repo;