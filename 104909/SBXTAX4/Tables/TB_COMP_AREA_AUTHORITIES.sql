CREATE TABLE sbxtax4.tb_comp_area_authorities (
  compliance_area_auth_id NUMBER(10) NOT NULL,
  compliance_area_id NUMBER(10) NOT NULL,
  authority_id NUMBER(10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;