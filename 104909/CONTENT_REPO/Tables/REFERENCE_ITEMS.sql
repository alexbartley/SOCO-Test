CREATE TABLE content_repo.reference_items (
  "ID" NUMBER NOT NULL,
  "VALUE" VARCHAR2(128 CHAR) NOT NULL,
  description VARCHAR2(1028 CHAR),
  value_type VARCHAR2(64 CHAR) NOT NULL,
  ref_nkid NUMBER,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  reference_group_id NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  next_rid NUMBER,
  nkid NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  reference_group_nkid NUMBER NOT NULL,
  CONSTRAINT reference_items_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT reference_items_f2 FOREIGN KEY (reference_group_id) REFERENCES content_repo.reference_groups ("ID"),
  CONSTRAINT reference_items_f4 FOREIGN KEY (value_type) REFERENCES content_repo.ref_value_types ("NAME")
) 
TABLESPACE content_repo
LOB (description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);