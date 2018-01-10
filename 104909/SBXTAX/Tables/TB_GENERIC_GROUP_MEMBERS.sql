CREATE TABLE sbxtax.tb_generic_group_members (
  generic_group_member_id NUMBER NOT NULL,
  generic_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(500 CHAR) NOT NULL,
  "VALUE" VARCHAR2(500 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;