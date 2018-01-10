CREATE TABLE sbxtax3.ht_filing_group_members (
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  filing_group_id NUMBER(10),
  filing_group_member_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  transaction_type VARCHAR2(2 BYTE),
  aud_filing_group_member_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;