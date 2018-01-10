CREATE TABLE sbxtax.tb_config (
  parm_id NUMBER NOT NULL,
  parm_name VARCHAR2(100 CHAR) NOT NULL,
  parm_value VARCHAR2(4000 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax
LOB (parm_value) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);