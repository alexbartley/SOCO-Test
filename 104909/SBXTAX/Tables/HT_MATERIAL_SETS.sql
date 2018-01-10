CREATE TABLE sbxtax.ht_material_sets (
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(200 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  material_set_id NUMBER(10),
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_material_set_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;