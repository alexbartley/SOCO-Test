CREATE TABLE sbxtax4.ht_exempt_cert_zones (
  created_by NUMBER(10),
  creation_date DATE,
  exempt_cert_id NUMBER(10),
  exempt_cert_zone_id NUMBER(10),
  exempt_type VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  zone_id NUMBER(10),
  aud_exempt_cert_zone_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;