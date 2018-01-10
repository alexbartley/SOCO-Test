CREATE TABLE sbxtax2.tb_filter_groups (
  filter_group_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 BYTE),
  description VARCHAR2(4000 BYTE),
  status VARCHAR2(1 BYTE),
  copy_of_id NUMBER,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  start_date DATE NOT NULL,
  end_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;