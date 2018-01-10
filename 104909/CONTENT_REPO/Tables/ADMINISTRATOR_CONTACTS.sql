CREATE TABLE content_repo.administrator_contacts (
  "ID" NUMBER NOT NULL,
  administrator_id NUMBER NOT NULL,
  source_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  usage_order NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  rid NUMBER,
  nkid NUMBER,
  next_rid NUMBER,
  administrator_nkid NUMBER NOT NULL,
  CONSTRAINT administrator_contacts_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT administrator_contacts_f2 FOREIGN KEY (administrator_id) REFERENCES content_repo.administrators ("ID"),
  CONSTRAINT administrator_contacts_f3 FOREIGN KEY (source_id) REFERENCES content_repo.research_sources ("ID")
) 
TABLESPACE content_repo;