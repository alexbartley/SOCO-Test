CREATE TABLE sbxtax4.tb_exempt_single_use (
  use_criteria_id NUMBER NOT NULL,
  exempt_cert_id NUMBER NOT NULL,
  xml_element VARCHAR2(100 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "VALUE" VARCHAR2(200 CHAR) NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;