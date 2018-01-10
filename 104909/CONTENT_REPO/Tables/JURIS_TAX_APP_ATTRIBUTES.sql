CREATE TABLE content_repo.juris_tax_app_attributes (
  "ID" NUMBER NOT NULL,
  juris_tax_applicability_id NUMBER NOT NULL,
  attribute_id NUMBER NOT NULL,
  "VALUE" VARCHAR2(5000 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP WITH TIME ZONE NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  juris_tax_applicability_nkid NUMBER NOT NULL,
  CONSTRAINT juris_tax_app_attributes_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT juris_tax_app_attributes_f1 FOREIGN KEY (attribute_id) REFERENCES content_repo.additional_attributes ("ID"),
  CONSTRAINT juris_tax_app_attributes_f2 FOREIGN KEY (juris_tax_applicability_id) REFERENCES content_repo.juris_tax_applicabilities ("ID")
) 
TABLESPACE content_repo
LOB ("VALUE") STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);