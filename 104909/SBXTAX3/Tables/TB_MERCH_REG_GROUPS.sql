CREATE TABLE sbxtax3.tb_merch_reg_groups (
  registration_group_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(100 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;