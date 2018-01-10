CREATE TABLE content_repo.gis_tb_comp_area_authorities (
  state_code VARCHAR2(2 CHAR),
  area_id VARCHAR2(60 CHAR),
  tax_area_id NUMBER(10),
  authority_name VARCHAR2(100 CHAR),
  nkid NUMBER,
  etl_date DATE
) 
TABLESPACE content_repo;