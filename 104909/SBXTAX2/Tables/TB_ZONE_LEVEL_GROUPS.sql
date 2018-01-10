CREATE TABLE sbxtax2.tb_zone_level_groups (
  zone_level_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(50 BYTE) NOT NULL,
  description VARCHAR2(200 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;