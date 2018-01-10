CREATE TABLE content_repo.juris_tax_impositions (
  "ID" NUMBER NOT NULL,
  jurisdiction_id NUMBER NOT NULL,
  tax_description_id NUMBER NOT NULL,
  reference_code VARCHAR2(50 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  description VARCHAR2(250 CHAR),
  revenue_purpose_id NUMBER,
  jurisdiction_nkid NUMBER NOT NULL,
  CONSTRAINT juris_tax_impositions_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT juris_tax_impositions_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT juris_tax_impositions_f1 FOREIGN KEY (revenue_purpose_id) REFERENCES content_repo.revenue_purposes ("ID"),
  CONSTRAINT juris_tax_impositions_f2 FOREIGN KEY (jurisdiction_id) REFERENCES content_repo.jurisdictions ("ID"),
  CONSTRAINT juris_tax_impositions_f3 FOREIGN KEY (tax_description_id) REFERENCES content_repo.tax_descriptions ("ID"),
  CONSTRAINT juris_tax_impositions_f6 FOREIGN KEY (rid,nkid) REFERENCES content_repo.jurisdiction_tax_revisions ("ID",nkid)
) 
TABLESPACE content_repo;