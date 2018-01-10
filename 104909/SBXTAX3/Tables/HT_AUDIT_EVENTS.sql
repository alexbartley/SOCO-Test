CREATE TABLE sbxtax3.ht_audit_events (
  audit_event_id NUMBER(10) NOT NULL,
  event_code VARCHAR2(200 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;