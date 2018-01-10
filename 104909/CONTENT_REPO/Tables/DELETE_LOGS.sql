CREATE TABLE content_repo.delete_logs (
  "ID" NUMBER NOT NULL,
  table_name VARCHAR2(50 CHAR) NOT NULL,
  primary_key NUMBER NOT NULL,
  deleted_by NUMBER NOT NULL,
  deleted_date TIMESTAMP NOT NULL,
  CONSTRAINT delete_logs_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;