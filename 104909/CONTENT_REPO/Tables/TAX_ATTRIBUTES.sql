CREATE TABLE content_repo.tax_attributes (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  juris_tax_imposition_id NUMBER NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  attribute_id NUMBER NOT NULL,
  "VALUE" VARCHAR2(500 CHAR) NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  juris_tax_imposition_nkid NUMBER NOT NULL,
  CONSTRAINT tax_attributes_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_attributes_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tax_attributes_f1v1 FOREIGN KEY (juris_tax_imposition_id) REFERENCES content_repo.juris_tax_impositions ("ID"),
  CONSTRAINT tax_attributes_f2 FOREIGN KEY (attribute_id) REFERENCES content_repo.additional_attributes ("ID")
) 
TABLESPACE content_repo;