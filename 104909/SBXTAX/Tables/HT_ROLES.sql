CREATE TABLE sbxtax.ht_roles (
  "ACTIVE" VARCHAR2(1 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(240 BYTE),
  grant_on_merch_create VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  role_id NUMBER(10),
  role_name VARCHAR2(30 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_role_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;