CREATE TABLE sbxtax2.tb_zone_authorities (
  zone_id NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  zone_authority_id NUMBER NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;