CREATE TABLE sbxtax3.tb_feature_licenses (
  feature_license_id NUMBER(10) NOT NULL,
  license_key_id NUMBER(10) NOT NULL,
  license_body BLOB NOT NULL,
  "ACTIVE" VARCHAR2(1 BYTE) NOT NULL,
  "HASH" VARCHAR2(50 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax
LOB (license_body) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW);