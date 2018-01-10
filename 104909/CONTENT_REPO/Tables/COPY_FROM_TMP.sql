CREATE TABLE content_repo.copy_from_tmp (
  process_id NUMBER,
  txt_start_date DATE,
  txt_end_date DATE,
  reference_code VARCHAR2(50 CHAR),
  jti_start_date DATE,
  jti_end_date DATE,
  juris_tax_app_id NUMBER,
  commodity_id NUMBER,
  applicability_type_id NUMBER,
  commodity_nkid NUMBER
) 
TABLESPACE content_repo;