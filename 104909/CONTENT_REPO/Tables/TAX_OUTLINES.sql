CREATE TABLE content_repo.tax_outlines (
  "ID" NUMBER NOT NULL,
  juris_tax_imposition_id NUMBER NOT NULL,
  calculation_structure_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  nkid NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  next_rid NUMBER,
  juris_tax_imposition_nkid NUMBER NOT NULL,
  CONSTRAINT tax_outlines_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_outlines_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_compositions_f2 FOREIGN KEY (juris_tax_imposition_id) REFERENCES content_repo.juris_tax_impositions ("ID"),
  CONSTRAINT tax_compositions_f3 FOREIGN KEY (calculation_structure_id) REFERENCES content_repo.tax_calculation_structures ("ID")
) 
TABLESPACE content_repo;