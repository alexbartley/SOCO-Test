CREATE TABLE content_repo.administrators (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  "NAME" VARCHAR2(250 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  requires_registration NUMBER(1) DEFAULT 0 NOT NULL,
  collects_tax NUMBER(1) DEFAULT 0 NOT NULL,
  notes VARCHAR2(4000 CHAR),
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  description VARCHAR2(250 CHAR),
  administrator_type_id NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  CONSTRAINT administrators_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT administrators_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT administrators_f2 FOREIGN KEY (administrator_type_id) REFERENCES content_repo.administrator_types ("ID"),
  CONSTRAINT administrators_f3 FOREIGN KEY (rid,nkid) REFERENCES content_repo.administrator_revisions ("ID",nkid)
) 
TABLESPACE content_repo
LOB (notes) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);