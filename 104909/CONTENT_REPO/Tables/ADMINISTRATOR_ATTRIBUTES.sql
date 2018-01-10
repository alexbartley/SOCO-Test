CREATE TABLE content_repo.administrator_attributes (
  "ID" NUMBER NOT NULL,
  administrator_id NUMBER NOT NULL,
  attribute_id NUMBER NOT NULL,
  "VALUE" VARCHAR2(500 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  start_date DATE,
  end_date DATE,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  administrator_nkid NUMBER NOT NULL,
  CONSTRAINT administrator_attributes_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT administrator_attributes_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT administrator_attributes_f2 FOREIGN KEY (attribute_id) REFERENCES content_repo.additional_attributes ("ID"),
  CONSTRAINT administrator_attributes_f4 FOREIGN KEY (administrator_id) REFERENCES content_repo.administrators ("ID")
) 
TABLESPACE content_repo;