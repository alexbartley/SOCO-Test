CREATE TABLE content_repo.kpmg_ext_area_detail (
  state_code VARCHAR2(2 CHAR) NOT NULL,
  unique_area VARCHAR2(32767 BYTE),
  area_id VARCHAR2(60 CHAR),
  start_date VARCHAR2(10 BYTE),
  end_date VARCHAR2(10 BYTE)
) 
TABLESPACE content_repo
LOB (unique_area) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);