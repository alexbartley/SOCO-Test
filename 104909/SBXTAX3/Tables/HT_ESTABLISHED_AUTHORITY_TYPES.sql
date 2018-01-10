CREATE TABLE sbxtax3.ht_established_authority_types (
  authority_type_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  default_established VARCHAR2(1 BYTE),
  default_tax_type VARCHAR2(100 BYTE),
  end_date DATE,
  established_auth_type_id NUMBER(10),
  established_zone_id NUMBER(10),
  interstate_tax_type_override VARCHAR2(100 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_established_auth_type_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;