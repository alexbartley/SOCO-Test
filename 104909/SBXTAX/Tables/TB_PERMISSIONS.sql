CREATE TABLE sbxtax.tb_permissions (
  permission_id NUMBER NOT NULL,
  "NAME" VARCHAR2(250 CHAR) NOT NULL,
  introduced_in_version VARCHAR2(50 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  description VARCHAR2(200 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;