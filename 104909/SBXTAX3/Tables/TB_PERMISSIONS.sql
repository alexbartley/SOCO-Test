CREATE TABLE sbxtax3.tb_permissions (
  permission_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(250 BYTE) NOT NULL,
  introduced_in_version VARCHAR2(50 BYTE),
  description VARCHAR2(200 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;