CREATE TABLE sbxtax.tb_contributing_authorities (
  contributing_authority_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  this_authority_id NUMBER NOT NULL,
  basis_percent NUMBER(31,10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;