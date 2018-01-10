CREATE TABLE content_repo.commodity_attributes (
  "ID" NUMBER NOT NULL,
  commodity_id NUMBER NOT NULL,
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
  commodity_nkid NUMBER NOT NULL,
  CONSTRAINT commodity_attributes_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT commodity_attributes_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT commodity_attributes_fkattr FOREIGN KEY (attribute_id) REFERENCES content_repo.additional_attributes ("ID"),
  CONSTRAINT commodity_attributes_fkcomm FOREIGN KEY (commodity_id) REFERENCES content_repo.commodities ("ID")
) 
TABLESPACE content_repo;