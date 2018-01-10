CREATE TABLE content_repo.gis_tb_comp_areas_tmp (
  state_code VARCHAR2(2 CHAR),
  area_id VARCHAR2(60 CHAR),
  unique_area VARCHAR2(500 CHAR),
  associated_area_count NUMBER,
  start_date DATE,
  end_date DATE,
  nkid NUMBER
) 
TABLESPACE content_repo;