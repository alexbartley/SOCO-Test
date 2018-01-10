CREATE TABLE content_repo.jurisdiction_attributes (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  jurisdiction_id NUMBER NOT NULL,
  attribute_id NUMBER NOT NULL,
  "VALUE" VARCHAR2(500 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  jurisdiction_nkid NUMBER NOT NULL,
  CONSTRAINT jurisdiction_attributes_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT juris_attribute_values_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT jurisdiction_attributes_f1 FOREIGN KEY (jurisdiction_id) REFERENCES content_repo.jurisdictions ("ID"),
  CONSTRAINT jurisdiction_attributes_f2 FOREIGN KEY (attribute_id) REFERENCES content_repo.additional_attributes ("ID")
) 
TABLESPACE content_repo;