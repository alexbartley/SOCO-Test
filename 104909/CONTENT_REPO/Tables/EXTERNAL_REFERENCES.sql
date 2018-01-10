CREATE TABLE content_repo.external_references (
  "ID" NUMBER NOT NULL,
  chng_id NUMBER,
  ref_system NUMBER NOT NULL,
  ref_id VARCHAR2(64 CHAR),
  ext_link VARCHAR2(2048 CHAR),
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP,
  entity_type NUMBER NOT NULL,
  PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo
LOB (ext_link) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);
COMMENT ON TABLE content_repo.external_references IS 'Light version 1';