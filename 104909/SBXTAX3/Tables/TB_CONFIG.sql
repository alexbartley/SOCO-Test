CREATE TABLE sbxtax3.tb_config (
  parm_id NUMBER(10) NOT NULL,
  parm_name VARCHAR2(100 BYTE) NOT NULL,
  parm_value VARCHAR2(4000 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;