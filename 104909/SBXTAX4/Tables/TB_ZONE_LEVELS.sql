CREATE TABLE sbxtax4.tb_zone_levels (
  zone_level_id NUMBER NOT NULL,
  zone_level_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(50 CHAR) NOT NULL,
  sequence_num NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  display_in_short_list VARCHAR2(1 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;