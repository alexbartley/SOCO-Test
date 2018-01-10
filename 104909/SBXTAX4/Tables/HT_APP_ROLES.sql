CREATE TABLE sbxtax4.ht_app_roles (
  "ACTIVE" VARCHAR2(1 BYTE),
  app_component_id NUMBER(10),
  app_role_id NUMBER(10),
  created_by NUMBER(10),
  create_flag VARCHAR2(1 BYTE),
  creation_date DATE,
  delete_flag VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  modify_flag VARCHAR2(1 BYTE),
  role_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  view_flag VARCHAR2(1 BYTE),
  aud_app_role_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;