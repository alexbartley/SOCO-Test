CREATE TABLE sbxtax3.tb_exempt_reasons (
  exempt_reason_id NUMBER(10) NOT NULL,
  customer_group_id NUMBER(10) NOT NULL,
  short_code VARCHAR2(2 BYTE) NOT NULL,
  long_code VARCHAR2(20 BYTE) NOT NULL,
  description VARCHAR2(200 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;