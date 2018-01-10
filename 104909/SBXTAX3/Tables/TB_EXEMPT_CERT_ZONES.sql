CREATE TABLE sbxtax3.tb_exempt_cert_zones (
  exempt_cert_zone_id NUMBER(10) NOT NULL,
  exempt_cert_id NUMBER(10) NOT NULL,
  zone_id NUMBER(10) NOT NULL,
  exempt_type VARCHAR2(1 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;