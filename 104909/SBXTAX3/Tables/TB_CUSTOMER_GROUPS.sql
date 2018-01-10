CREATE TABLE sbxtax3.tb_customer_groups (
  customer_group_id NUMBER(10) NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(500 BYTE),
  merchant_id NUMBER(10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;