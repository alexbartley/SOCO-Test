CREATE TABLE sbxtax3.tb_compliance_areas (
  compliance_area_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(500 BYTE) NOT NULL,
  compliance_area_uuid VARCHAR2(32 BYTE) NOT NULL,
  effective_zone_level_id NUMBER(10) NOT NULL,
  associated_area_count NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;