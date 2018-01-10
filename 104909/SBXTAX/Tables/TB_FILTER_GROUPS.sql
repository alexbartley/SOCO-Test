CREATE TABLE sbxtax.tb_filter_groups (
  filter_group_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR),
  description VARCHAR2(4000 CHAR),
  status VARCHAR2(1 CHAR),
  copy_of_id NUMBER,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax
LOB (description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);