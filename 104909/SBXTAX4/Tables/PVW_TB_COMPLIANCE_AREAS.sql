CREATE TABLE sbxtax4.pvw_tb_compliance_areas (
  compliance_area_id NUMBER(10),
  "NAME" VARCHAR2(500 CHAR),
  compliance_area_uuid VARCHAR2(32 CHAR),
  effective_zone_level_id NUMBER(10),
  associated_area_count NUMBER(10),
  merchant_id NUMBER(10),
  start_date DATE,
  end_date DATE,
  change_type VARCHAR2(20 CHAR)
) 
TABLESPACE ositax;