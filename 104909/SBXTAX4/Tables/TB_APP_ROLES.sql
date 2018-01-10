CREATE TABLE sbxtax4.tb_app_roles (
  app_role_id NUMBER,
  role_id NUMBER NOT NULL,
  app_component_id NUMBER NOT NULL,
  create_flag VARCHAR2(1 CHAR),
  modify_flag VARCHAR2(1 CHAR),
  delete_flag VARCHAR2(1 CHAR),
  view_flag VARCHAR2(1 CHAR),
  "ACTIVE" VARCHAR2(1 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;