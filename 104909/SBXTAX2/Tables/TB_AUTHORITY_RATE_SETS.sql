CREATE TABLE sbxtax2.tb_authority_rate_sets (
  authority_rate_set_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  authority_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  material_set_id NUMBER(10) NOT NULL,
  description VARCHAR2(200 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;