CREATE TABLE content_repo.update_multiple_log (
  process_id NUMBER NOT NULL,
  gendate TIMESTAMP,
  status NUMBER,
  errmsg CLOB,
  entity NUMBER,
  "ACTION" VARCHAR2(1 CHAR),
  eid NUMBER,
  primary_key NUMBER,
  mlt_section NUMBER
) 
TABLESPACE content_repo
LOB (errmsg) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW);