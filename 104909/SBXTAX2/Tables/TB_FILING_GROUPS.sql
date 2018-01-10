CREATE TABLE sbxtax2.tb_filing_groups (
  filing_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  merchant_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  start_date DATE NOT NULL,
  authority_id NUMBER,
  registration_number VARCHAR2(50 BYTE),
  end_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;