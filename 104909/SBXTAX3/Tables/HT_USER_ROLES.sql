CREATE TABLE sbxtax3.ht_user_roles (
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  grant_flag VARCHAR2(1 BYTE),
  is_cascading VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  role_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  user_id NUMBER(10),
  user_role_id NUMBER(10),
  aud_user_role_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;