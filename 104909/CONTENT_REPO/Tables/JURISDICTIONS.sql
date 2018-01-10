CREATE TABLE content_repo.jurisdictions (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  official_name VARCHAR2(250 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  description VARCHAR2(1000 CHAR),
  currency_id NUMBER NOT NULL,
  geo_area_category_id NUMBER NOT NULL,
  default_admin_id NUMBER,
  CONSTRAINT jurisdiction_identifiers_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT jurisdiction_identifiers_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT jurisdictions_f1 FOREIGN KEY (geo_area_category_id) REFERENCES content_repo.geo_area_categories ("ID"),
  CONSTRAINT jurisdictions_f2 FOREIGN KEY (currency_id) REFERENCES content_repo.currencies ("ID"),
  CONSTRAINT jurisdiction_identifiers_f2 FOREIGN KEY (rid,nkid) REFERENCES content_repo.jurisdiction_revisions ("ID",nkid)
) 
TABLESPACE content_repo;