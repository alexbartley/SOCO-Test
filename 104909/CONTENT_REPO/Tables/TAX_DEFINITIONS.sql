CREATE TABLE content_repo.tax_definitions (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  min_threshold NUMBER NOT NULL,
  max_limit NUMBER,
  value_type VARCHAR2(15 CHAR) NOT NULL,
  "VALUE" NUMBER,
  defer_to_juris_tax_id NUMBER,
  currency_id NUMBER,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  tax_outline_id NUMBER NOT NULL,
  defer_to_juris_tax_nkid NUMBER,
  tax_outline_nkid NUMBER NOT NULL,
  CONSTRAINT tax_definitions_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_definitions_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_definitions_f2 FOREIGN KEY (defer_to_juris_tax_id) REFERENCES content_repo.juris_tax_impositions ("ID"),
  CONSTRAINT tax_definitions_f4 FOREIGN KEY (currency_id) REFERENCES content_repo.currencies ("ID"),
  CONSTRAINT tax_definitions_f5 FOREIGN KEY (tax_outline_id) REFERENCES content_repo.tax_outlines ("ID")
) 
TABLESPACE content_repo;