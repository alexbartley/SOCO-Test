CREATE TABLE sbxtax.tb_filing_group_members (
  filing_group_member_id NUMBER NOT NULL,
  filing_group_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  transaction_type VARCHAR2(2 CHAR) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;