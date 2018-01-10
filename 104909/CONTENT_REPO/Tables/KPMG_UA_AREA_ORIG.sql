CREATE TABLE content_repo.kpmg_ua_area_orig (
  unique_area VARCHAR2(32767 CHAR),
  area_id VARCHAR2(60 CHAR),
  state_code VARCHAR2(2 CHAR) NOT NULL
) 
TABLESPACE content_repo
LOB (unique_area) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);