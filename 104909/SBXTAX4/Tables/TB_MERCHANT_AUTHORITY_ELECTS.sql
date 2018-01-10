CREATE TABLE sbxtax4.tb_merchant_authority_elects (
  merchant_authority_elect_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;