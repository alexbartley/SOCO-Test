CREATE TABLE content_repo.research_source_contacts (
  "ID" NUMBER NOT NULL,
  research_source_id NUMBER NOT NULL,
  contact_type_id NUMBER NOT NULL,
  contact_details VARCHAR2(500 CHAR) NOT NULL,
  contact_notes VARCHAR2(4000 CHAR),
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT -2 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  language_id NUMBER,
  start_date DATE,
  end_date DATE,
  CONSTRAINT research_source_contacts_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT research_source_contacts_f1 FOREIGN KEY (research_source_id) REFERENCES content_repo.research_sources ("ID"),
  CONSTRAINT research_source_contacts_f2 FOREIGN KEY (contact_type_id) REFERENCES content_repo.contact_types ("ID"),
  CONSTRAINT research_source_contacts_f3 FOREIGN KEY (language_id) REFERENCES content_repo.languages ("ID")
) 
TABLESPACE content_repo
LOB (contact_notes) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);