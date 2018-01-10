CREATE TABLE content_repo.tdr_etl_map_jta_rq (
  jurisdiction_nkid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  rqs VARCHAR2(32767 BYTE),
  start_date DATE,
  end_date DATE
) 
TABLESPACE content_repo
LOB (rqs) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);