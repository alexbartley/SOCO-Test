CREATE TABLE sbxtax4.ht_units_of_measure (
  base VARCHAR2(25 BYTE),
  "CATEGORY" VARCHAR2(50 BYTE),
  code VARCHAR2(25 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(200 BYTE),
  end_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(50 BYTE),
  rounding_precision NUMBER(31,5),
  rounding_rule VARCHAR2(10 BYTE),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  unit_of_measure_id NUMBER(10),
  aud_units_of_measure_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;