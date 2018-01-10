CREATE TABLE sbxtax4.tb_app_component (
  app_component_id NUMBER NOT NULL,
  target_url VARCHAR2(2000 CHAR),
  parent_app_component_id NUMBER,
  "NAME" VARCHAR2(30 CHAR) NOT NULL,
  "VERSION" VARCHAR2(30 CHAR),
  display_order NUMBER NOT NULL,
  url VARCHAR2(2000 CHAR),
  description VARCHAR2(2000 CHAR),
  "TYPE" VARCHAR2(15 CHAR) NOT NULL,
  "ACTIVE" VARCHAR2(1 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  schema_required_flag VARCHAR2(1 CHAR),
  page_title VARCHAR2(30 CHAR),
  menu_title VARCHAR2(30 CHAR),
  comp_help_url VARCHAR2(2000 CHAR),
  user_restricted VARCHAR2(1 CHAR),
  requires_content_provider VARCHAR2(1 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax
LOB (comp_help_url) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (target_url) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (url) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);