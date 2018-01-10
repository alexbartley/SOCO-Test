CREATE TABLE sbxtax3.tb_app_roles (
  app_role_id NUMBER(10) NOT NULL,
  role_id NUMBER(10) NOT NULL,
  app_component_id NUMBER(10) NOT NULL,
  create_flag VARCHAR2(1 BYTE),
  modify_flag VARCHAR2(1 BYTE),
  delete_flag VARCHAR2(1 BYTE),
  view_flag VARCHAR2(1 BYTE),
  "ACTIVE" VARCHAR2(1 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;