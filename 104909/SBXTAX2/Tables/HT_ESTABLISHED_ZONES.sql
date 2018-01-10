CREATE TABLE sbxtax2.ht_established_zones (
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  established_type VARCHAR2(1 BYTE),
  established_zone_id NUMBER(10),
  interstate_tax_type_override VARCHAR2(100 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  tax_type VARCHAR2(100 BYTE),
  zone_id NUMBER(10),
  aud_established_zone_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;