CREATE TABLE sbxtax3.ht_authority_logic_group_xref (
  authority_id NUMBER(10),
  authority_logic_group_id NUMBER(10),
  authority_logic_group_xref_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  process_order NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_auth_logic_group_xref_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;