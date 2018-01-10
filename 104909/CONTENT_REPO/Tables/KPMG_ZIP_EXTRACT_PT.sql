CREATE TABLE content_repo.kpmg_zip_extract_pt (
  area_id VARCHAR2(60 CHAR),
  zip VARCHAR2(5 CHAR),
  plus4_range VARCHAR2(16 CHAR),
  default_flag CHAR,
  state_code VARCHAR2(2 CHAR) NOT NULL
) 
TABLESPACE content_repo;