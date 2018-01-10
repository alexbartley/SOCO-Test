CREATE TABLE sbxtax.tb_zone_authorities (
  zone_authority_id NUMBER NOT NULL,
  zone_id NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;