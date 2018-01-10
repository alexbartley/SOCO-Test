CREATE TABLE content_repo.entity_table_map (
  table_name VARCHAR2(30 CHAR) NOT NULL,
  logical_entity VARCHAR2(32 CHAR),
  "ID" NUMBER,
  ui_alias VARCHAR2(50 CHAR)
) 
TABLESPACE content_repo;