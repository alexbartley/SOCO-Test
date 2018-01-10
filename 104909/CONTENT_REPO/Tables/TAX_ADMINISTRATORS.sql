CREATE TABLE content_repo.tax_administrators (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  juris_tax_imposition_id NUMBER NOT NULL,
  administrator_id NUMBER NOT NULL,
  location_id NUMBER,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  collector_id NUMBER,
  administrator_nkid NUMBER NOT NULL,
  juris_tax_imposition_nkid NUMBER NOT NULL,
  collector_nkid NUMBER,
  CONSTRAINT tax_administrators_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_juris_administrators_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_administrators_f3 FOREIGN KEY (juris_tax_imposition_id) REFERENCES content_repo.juris_tax_impositions ("ID"),
  CONSTRAINT tax_administrators_f5 FOREIGN KEY (administrator_id) REFERENCES content_repo.administrators ("ID")
) 
TABLESPACE content_repo;