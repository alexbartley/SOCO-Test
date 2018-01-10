CREATE TABLE content_repo.tax_calculation_structures (
  "ID" NUMBER NOT NULL,
  tax_structure_type_id NUMBER NOT NULL,
  amount_type_id NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  description VARCHAR2(1000 CHAR),
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT tax_calculation_structures_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_calculation_structures_f1 FOREIGN KEY (tax_structure_type_id) REFERENCES content_repo.tax_structure_types ("ID"),
  CONSTRAINT tax_calculation_structures_f2 FOREIGN KEY (amount_type_id) REFERENCES content_repo.amount_types ("ID")
) 
TABLESPACE content_repo;