CREATE TABLE content_repo.consumer_key_mapping (
  "ID" NUMBER NOT NULL,
  consumer_tag VARCHAR2(250 CHAR) NOT NULL,
  table_name VARCHAR2(30 CHAR) NOT NULL,
  field VARCHAR2(128 CHAR) NOT NULL,
  cr_entity VARCHAR2(128 CHAR) NOT NULL
) 
TABLESPACE content_repo;