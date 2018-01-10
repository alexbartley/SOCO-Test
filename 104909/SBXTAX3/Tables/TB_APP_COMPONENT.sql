CREATE TABLE sbxtax3.tb_app_component (
  app_component_id NUMBER(10) NOT NULL,
  target_url VARCHAR2(2000 BYTE),
  parent_app_component_id NUMBER(10),
  "NAME" VARCHAR2(30 BYTE) NOT NULL,
  "VERSION" VARCHAR2(30 BYTE),
  display_order NUMBER(10) NOT NULL,
  url VARCHAR2(2000 BYTE),
  description VARCHAR2(2000 BYTE),
  "TYPE" VARCHAR2(15 BYTE) NOT NULL,
  "ACTIVE" VARCHAR2(1 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  schema_required_flag VARCHAR2(1 BYTE),
  page_title VARCHAR2(30 BYTE),
  menu_title VARCHAR2(30 BYTE),
  comp_help_url VARCHAR2(2000 BYTE),
  user_restricted VARCHAR2(1 BYTE),
  requires_content_provider VARCHAR2(1 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;