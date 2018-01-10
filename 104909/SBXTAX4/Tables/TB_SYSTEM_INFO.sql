CREATE TABLE sbxtax4.tb_system_info (
  system_info_id NUMBER,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  info VARCHAR2(100 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;