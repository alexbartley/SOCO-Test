CREATE TABLE sbxtax4.tb_roles (
  role_id NUMBER NOT NULL,
  role_name VARCHAR2(30 CHAR) NOT NULL,
  last_update_date DATE,
  grant_on_merch_create VARCHAR2(1 CHAR) NOT NULL,
  description VARCHAR2(240 CHAR) NOT NULL,
  "ACTIVE" VARCHAR2(1 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;