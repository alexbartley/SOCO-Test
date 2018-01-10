CREATE TABLE content_repo.juris_tax_descriptions (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  jurisdiction_id NUMBER NOT NULL,
  tax_description_id NUMBER NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  jurisdiction_nkid NUMBER NOT NULL,
  CONSTRAINT juris_tax_descriptions_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT juris_tax_descriptions_f1 FOREIGN KEY (jurisdiction_id) REFERENCES content_repo.jurisdictions ("ID"),
  CONSTRAINT juris_tax_descriptions_f2 FOREIGN KEY (tax_description_id) REFERENCES content_repo.tax_descriptions ("ID")
) 
TABLESPACE content_repo;