CREATE TABLE sbxtax3.tb_rate_tiers (
  rate_tier_id NUMBER(10) NOT NULL,
  rate_id NUMBER(10) NOT NULL,
  rate NUMBER(31,10),
  flat_fee NUMBER(31,10),
  amount_low NUMBER(31,5) NOT NULL,
  amount_high NUMBER(31,5),
  rate_code VARCHAR2(50 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;