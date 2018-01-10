CREATE TABLE sbxtax.tb_tasks (
  task_id NUMBER NOT NULL,
  user_id NUMBER,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  description VARCHAR2(200 CHAR),
  start_date DATE,
  completion_date DATE,
  status VARCHAR2(4000 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "TYPE" VARCHAR2(10 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax
LOB (status) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);