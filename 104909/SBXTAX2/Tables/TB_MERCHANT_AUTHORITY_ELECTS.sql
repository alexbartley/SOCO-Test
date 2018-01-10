CREATE TABLE sbxtax2.tb_merchant_authority_elects (
  merchant_authority_elect_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  authority_id NUMBER(10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;