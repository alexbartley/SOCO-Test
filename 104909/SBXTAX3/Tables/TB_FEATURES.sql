CREATE TABLE sbxtax3.tb_features (
  "FEATURE_ID" NUMBER(10) NOT NULL,
  feature_type_id NUMBER(10) NOT NULL,
  description VARCHAR2(1000 BYTE) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;