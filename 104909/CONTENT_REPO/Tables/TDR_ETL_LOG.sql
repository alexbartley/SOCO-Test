CREATE TABLE content_repo.tdr_etl_log (
  "ID" NUMBER GENERATED AS IDENTITY,
  process_id NUMBER,
  entity_name VARCHAR2(20 BYTE),
  start_time TIMESTAMP,
  stop_time TIMESTAMP,
  status NUMBER,
  tag_group VARCHAR2(50 BYTE),
  instance_name VARCHAR2(20 BYTE),
  tag_instance VARCHAR2(50 BYTE)
) 
TABLESPACE content_repo;