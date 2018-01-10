CREATE TABLE content_repo.kpmg_ext_jurisdictions (
  jurisdiction_name VARCHAR2(250 CHAR),
  description VARCHAR2(1000 CHAR),
  geo_area VARCHAR2(200 CHAR),
  start_date VARCHAR2(10 CHAR),
  end_date VARCHAR2(10 CHAR)
) 
TABLESPACE content_repo;