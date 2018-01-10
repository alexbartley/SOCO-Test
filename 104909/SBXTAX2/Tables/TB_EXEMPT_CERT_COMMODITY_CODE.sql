CREATE TABLE sbxtax2.tb_exempt_cert_commodity_code (
  exempt_cert_commodity_code_id NUMBER(10) NOT NULL,
  exempt_cert_id NUMBER(10) NOT NULL,
  commodity_code_match VARCHAR2(100 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;