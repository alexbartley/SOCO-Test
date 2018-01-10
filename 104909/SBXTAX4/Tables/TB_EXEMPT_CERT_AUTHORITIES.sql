CREATE TABLE sbxtax4.tb_exempt_cert_authorities (
  exempt_cert_authority_id NUMBER NOT NULL,
  exempt_cert_id NUMBER NOT NULL,
  exempt_cert_authority_type_id NUMBER NOT NULL,
  authority_id NUMBER,
  "EXEMPT" VARCHAR2(1 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;