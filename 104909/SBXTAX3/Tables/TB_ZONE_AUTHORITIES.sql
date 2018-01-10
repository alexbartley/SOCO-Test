CREATE TABLE sbxtax3.tb_zone_authorities (
  zone_authority_id NUMBER(10) NOT NULL,
  zone_id NUMBER(10) NOT NULL,
  authority_id NUMBER(10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;