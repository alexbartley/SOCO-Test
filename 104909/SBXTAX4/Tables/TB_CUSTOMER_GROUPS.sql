CREATE TABLE sbxtax4.tb_customer_groups (
  customer_group_id NUMBER NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "NAME" VARCHAR2(100 CHAR),
  description VARCHAR2(500 CHAR),
  merchant_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;