CREATE TABLE sbxtax2.ct_tb_lookups_f (
  lookup_id NUMBER(10) NOT NULL,
  code_group VARCHAR2(15 BYTE) NOT NULL,
  code VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(200 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "ACTIVE" VARCHAR2(1 BYTE) NOT NULL
) 
TABLESPACE ositax;