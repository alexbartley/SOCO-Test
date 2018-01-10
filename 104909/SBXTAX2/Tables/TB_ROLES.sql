CREATE TABLE sbxtax2.tb_roles (
  role_id NUMBER(10) NOT NULL,
  role_name VARCHAR2(30 BYTE) NOT NULL,
  description VARCHAR2(240 BYTE) NOT NULL,
  "ACTIVE" VARCHAR2(1 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  grant_on_merch_create VARCHAR2(1 BYTE) NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;