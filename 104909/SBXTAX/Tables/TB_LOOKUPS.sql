CREATE TABLE sbxtax.tb_lookups (
  lookup_id NUMBER,
  code_group VARCHAR2(15 CHAR) NOT NULL,
  code VARCHAR2(100 CHAR) NOT NULL,
  description VARCHAR2(200 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "ACTIVE" VARCHAR2(1 CHAR) NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;