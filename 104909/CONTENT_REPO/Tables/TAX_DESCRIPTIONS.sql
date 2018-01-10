CREATE TABLE content_repo.tax_descriptions (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(500 CHAR) NOT NULL,
  transaction_type_id NUMBER NOT NULL,
  taxation_type_id NUMBER NOT NULL,
  spec_applicability_type_id NUMBER NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_date TIMESTAMP NOT NULL,
  entered_by NUMBER NOT NULL,
  description VARCHAR2(500 CHAR),
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  CONSTRAINT tax_descriptions_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_descriptions_f2 FOREIGN KEY (transaction_type_id) REFERENCES content_repo.transaction_types ("ID"),
  CONSTRAINT tax_descriptions_f3 FOREIGN KEY (taxation_type_id) REFERENCES content_repo.taxation_types ("ID"),
  CONSTRAINT tax_descriptions_f4 FOREIGN KEY (spec_applicability_type_id) REFERENCES content_repo.specific_applicability_types ("ID")
) 
TABLESPACE content_repo;