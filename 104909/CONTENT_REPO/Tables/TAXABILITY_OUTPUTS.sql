CREATE TABLE content_repo.taxability_outputs (
  "ID" NUMBER NOT NULL,
  juris_tax_applicability_id NUMBER NOT NULL,
  short_text VARCHAR2(250 CHAR) NOT NULL,
  full_text VARCHAR2(500 CHAR),
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  rid NUMBER NOT NULL,
  next_rid NUMBER,
  nkid NUMBER NOT NULL,
  juris_tax_applicability_nkid NUMBER NOT NULL,
  tax_applicability_tax_id NUMBER,
  tax_applicability_tax_nkid NUMBER,
  start_date DATE,
  end_date DATE,
  CONSTRAINT taxability_outputs_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT taxability_outputs_f2 FOREIGN KEY (juris_tax_applicability_id) REFERENCES content_repo.juris_tax_applicabilities ("ID")
) 
TABLESPACE content_repo;