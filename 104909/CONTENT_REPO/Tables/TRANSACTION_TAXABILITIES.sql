CREATE TABLE content_repo.transaction_taxabilities (
  "ID" NUMBER NOT NULL,
  juris_tax_applicability_id NUMBER NOT NULL,
  applicability_type_id NUMBER,
  reference_code VARCHAR2(100 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP WITH TIME ZONE NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  CONSTRAINT transaction_taxabilities_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;