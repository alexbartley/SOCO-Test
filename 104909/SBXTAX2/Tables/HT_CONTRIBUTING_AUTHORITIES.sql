CREATE TABLE sbxtax2.ht_contributing_authorities (
  authority_id NUMBER(10),
  basis_percent NUMBER(31,10),
  contributing_authority_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  this_authority_id NUMBER(10),
  aud_contributing_authority_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;