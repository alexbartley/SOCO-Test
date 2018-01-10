CREATE TABLE sbxtax4.tb_zone_level_groups (
  zone_level_group_id NUMBER NOT NULL,
  description VARCHAR2(200 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "NAME" VARCHAR2(50 CHAR) NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;