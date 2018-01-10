CREATE TABLE sbxtax2.tb_filters (
  filter_id NUMBER NOT NULL,
  filter_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(4000 BYTE),
  parent_filter_id NUMBER,
  ordering NUMBER,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  display_order NUMBER(10)
) 
TABLESPACE ositax;