CREATE TABLE sbxtax2.tb_exempt_reasons (
  exempt_reason_id NUMBER NOT NULL,
  short_code VARCHAR2(2 BYTE) NOT NULL,
  long_code VARCHAR2(20 BYTE) NOT NULL,
  description VARCHAR2(200 BYTE),
  created_by NUMBER,
  creation_date DATE,
  last_updated_by NUMBER,
  last_update_date DATE,
  customer_group_id NUMBER NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;