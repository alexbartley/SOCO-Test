CREATE TABLE sbxtax.ht_established_authorities (
  authority_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  established VARCHAR2(1 BYTE),
  established_authority_id NUMBER(10),
  established_authority_type_id NUMBER(10),
  interstate_tax_type_override VARCHAR2(100 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  tax_type VARCHAR2(100 BYTE),
  aud_established_authority_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;