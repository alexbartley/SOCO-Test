CREATE TABLE sbxtax2.ht_feature_licenses (
  "ACTIVE" VARCHAR2(1 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  feature_license_id NUMBER(10),
  "HASH" VARCHAR2(50 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  license_body BLOB,
  license_key_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_feature_license_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax
LOB (license_body) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW);