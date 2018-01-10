CREATE TABLE sbxtax.ht_compliance_areas (
  associated_area_count NUMBER(10),
  compliance_area_id NUMBER(10),
  compliance_area_uuid VARCHAR2(32 CHAR),
  created_by NUMBER(10),
  creation_date DATE,
  effective_zone_level_id NUMBER(10),
  end_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(500 CHAR),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_compliance_area_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 CHAR) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;