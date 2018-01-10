CREATE TABLE content_repo.gis_tb_comp_area_dupe_tmp (
  state_code VARCHAR2(2 CHAR),
  area_id VARCHAR2(60 CHAR),
  unique_area VARCHAR2(500 CHAR),
  tax_area_id NUMBER(10),
  tax_areaid_startdate DATE,
  tax_areaid_enddate DATE,
  associated_area_count NUMBER(10),
  effective_zone_level_id NUMBER(10),
  merchant_id NUMBER(10),
  start_date DATE,
  end_date DATE,
  etl_date DATE
) 
TABLESPACE content_repo;