CREATE TABLE content_repo.tax_applicability_taxes (
  "ID" NUMBER NOT NULL,
  juris_tax_imposition_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  nkid NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  next_rid NUMBER,
  juris_tax_applicability_id NUMBER,
  juris_tax_applicability_nkid NUMBER NOT NULL,
  juris_tax_imposition_nkid NUMBER NOT NULL,
  ref_rule_order NUMBER,
  tax_type VARCHAR2(4 CHAR),
  tax_type_id NUMBER,
  CONSTRAINT tax_applicability_taxes_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_applicability_taxes_f2 FOREIGN KEY (juris_tax_applicability_id) REFERENCES content_repo.juris_tax_applicabilities ("ID"),
  CONSTRAINT tax_applicability_taxes_f3 FOREIGN KEY (juris_tax_imposition_id) REFERENCES content_repo.juris_tax_impositions ("ID")
) TABLESPACE content_repo
PARTITION BY HASH ("ID")
(PARTITION
  INDEXING ON
  TABLESPACE tax_app_set,
PARTITION
  INDEXING ON
  TABLESPACE tax_app_set,
PARTITION
  INDEXING ON
  TABLESPACE tax_app_set,
PARTITION
  INDEXING ON
  TABLESPACE tax_app_set,
PARTITION
  INDEXING ON
  TABLESPACE tax_app_set,
PARTITION
  INDEXING ON
  TABLESPACE tax_app_set);