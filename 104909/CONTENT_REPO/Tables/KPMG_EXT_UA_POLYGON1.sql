CREATE TABLE content_repo.kpmg_ext_ua_polygon1 (
  unique_area VARCHAR2(5000 BYTE),
  area_id VARCHAR2(100 CHAR),
  geo_area_key VARCHAR2(200 CHAR)
) 
TABLESPACE content_repo
LOB (unique_area) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);