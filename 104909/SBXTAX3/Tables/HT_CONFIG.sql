CREATE TABLE sbxtax3.ht_config (
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  parm_id NUMBER(10),
  parm_name VARCHAR2(100 BYTE),
  parm_value VARCHAR2(4000 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_config_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;