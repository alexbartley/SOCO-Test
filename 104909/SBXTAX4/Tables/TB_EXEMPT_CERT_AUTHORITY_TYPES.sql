CREATE TABLE sbxtax4.tb_exempt_cert_authority_types (
  exempt_cert_auth_type_id NUMBER,
  last_updated_by NUMBER(10),
  exempt_cert_id NUMBER NOT NULL,
  exempt_cert_zone_id NUMBER NOT NULL,
  authority_type_id NUMBER,
  default_exempt VARCHAR2(1 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;