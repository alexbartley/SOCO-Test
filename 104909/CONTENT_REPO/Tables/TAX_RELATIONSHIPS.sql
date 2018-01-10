CREATE TABLE content_repo.tax_relationships (
  "ID" NUMBER NOT NULL,
  jurisdiction_id NUMBER NOT NULL,
  jurisdiction_nkid NUMBER NOT NULL,
  jurisdiction_rid NUMBER NOT NULL,
  related_jurisdiction_id NUMBER,
  related_jurisdiction_nkid NUMBER,
  relationship_type VARCHAR2(100 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  start_date DATE,
  end_date DATE,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  basis_percent NUMBER,
  CONSTRAINT tax_relationships_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_relationships_f2 FOREIGN KEY (jurisdiction_id) REFERENCES content_repo.jurisdictions ("ID"),
  CONSTRAINT tax_relationships_f3 FOREIGN KEY (related_jurisdiction_id) REFERENCES content_repo.jurisdictions ("ID")
) 
TABLESPACE content_repo;