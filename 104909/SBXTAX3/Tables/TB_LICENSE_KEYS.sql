CREATE TABLE sbxtax3.tb_license_keys (
  license_key_id NUMBER(10) NOT NULL,
  license_key_body VARCHAR2(40 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;