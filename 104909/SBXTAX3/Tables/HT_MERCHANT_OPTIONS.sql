CREATE TABLE sbxtax3.ht_merchant_options (
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  merchant_option_id NUMBER(10),
  option_lookup_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  type_lookup_id NUMBER(10),
  "VALUE" VARCHAR2(200 BYTE),
  aud_merchant_option_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;