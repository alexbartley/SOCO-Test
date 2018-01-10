CREATE TABLE sbxtax4.ht_authority_type_aliases (
  authority_type_alias_id NUMBER(10),
  authority_type_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(1000 BYTE),
  end_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_authority_type_alias_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;