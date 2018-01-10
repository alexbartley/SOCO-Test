CREATE TABLE sbxtax4.tb_exempt_reasons (
  exempt_reason_id NUMBER NOT NULL,
  customer_group_id NUMBER NOT NULL,
  short_code VARCHAR2(2 CHAR) NOT NULL,
  long_code VARCHAR2(20 CHAR) NOT NULL,
  description VARCHAR2(200 CHAR),
  created_by NUMBER,
  creation_date DATE,
  last_updated_by NUMBER,
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;