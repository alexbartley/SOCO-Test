CREATE TABLE sbxtax3.tb_filing_groups (
  filing_group_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  authority_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  registration_number VARCHAR2(50 BYTE),
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;