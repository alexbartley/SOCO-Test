CREATE TABLE content_repo.kpmg_export_areas_file (
  a_state_code VARCHAR2(2 CHAR),
  a_unique_area VARCHAR2(2000 BYTE),
  a_area_id VARCHAR2(50 CHAR),
  a_start_date VARCHAR2(30 CHAR),
  a_end_date VARCHAR2(30 CHAR),
  b_unique_area VARCHAR2(5000 BYTE),
  b_area_id VARCHAR2(100 CHAR),
  b_geo_area_key VARCHAR2(200 CHAR),
  c_geo_area_key VARCHAR2(200 CHAR),
  c_geo_area VARCHAR2(200 CHAR),
  c_start_date VARCHAR2(20 CHAR),
  c_end_date VARCHAR2(20 CHAR)
) 
TABLESPACE content_repo
LOB (b_unique_area) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);