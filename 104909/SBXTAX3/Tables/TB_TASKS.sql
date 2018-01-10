CREATE TABLE sbxtax3.tb_tasks (
  task_id NUMBER(10) NOT NULL,
  user_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(200 BYTE),
  start_date DATE,
  completion_date DATE,
  status VARCHAR2(4000 BYTE),
  "TYPE" VARCHAR2(10 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;