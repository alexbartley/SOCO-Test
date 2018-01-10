CREATE TABLE content_repo.tdr_etl_instances (
  "ID" NUMBER NOT NULL,
  instance_name VARCHAR2(50 BYTE),
  schema_name VARCHAR2(10 BYTE),
  CONSTRAINT tdr_etl_instance_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;