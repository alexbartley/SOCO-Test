CREATE TABLE content_repo.tran_tax_qualifiers (
  "ID" NUMBER NOT NULL,
  juris_tax_applicability_id NUMBER NOT NULL,
  taxability_element_id NUMBER,
  logical_qualifier VARCHAR2(100 CHAR) NOT NULL,
  "VALUE" VARCHAR2(100 CHAR),
  element_qual_group VARCHAR2(100 CHAR),
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP WITH TIME ZONE NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  jurisdiction_id NUMBER,
  reference_group_id NUMBER,
  qualifier_type VARCHAR2(16 CHAR),
  juris_tax_applicability_nkid NUMBER NOT NULL,
  reference_group_nkid NUMBER,
  jurisdiction_nkid NUMBER,
  CONSTRAINT tran_tax_qualifiers_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tran_tax_qualifiers_f3 FOREIGN KEY (taxability_element_id) REFERENCES content_repo.taxability_elements ("ID"),
  CONSTRAINT tran_tax_qualifiers_f4 FOREIGN KEY (juris_tax_applicability_id) REFERENCES content_repo.juris_tax_applicabilities ("ID"),
  CONSTRAINT tran_tax_qualifiers_f5 FOREIGN KEY (reference_group_id) REFERENCES content_repo.reference_groups ("ID")
) 
TABLESPACE content_repo;