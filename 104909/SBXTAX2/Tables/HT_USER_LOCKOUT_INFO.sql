CREATE TABLE sbxtax2.ht_user_lockout_info (
  created_by NUMBER(10),
  creation_date DATE,
  failed_login_count NUMBER(10),
  first_failed_at DATE,
  is_locked VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  locked_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  user_id NUMBER(10),
  user_lockout_id NUMBER(10),
  aud_user_lockout_info_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;