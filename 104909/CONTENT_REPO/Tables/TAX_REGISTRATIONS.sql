CREATE TABLE content_repo.tax_registrations (
  "ID" NUMBER NOT NULL,
  administrator_id NUMBER NOT NULL,
  registration_mask VARCHAR2(100 CHAR) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  administrator_nkid NUMBER NOT NULL,
  CONSTRAINT tax_registrations_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_registrations_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_registrations_f1 FOREIGN KEY (administrator_id) REFERENCES content_repo.administrators ("ID")
) 
TABLESPACE content_repo;