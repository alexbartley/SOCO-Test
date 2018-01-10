CREATE TABLE sbxtax4.tb_rate_tiers (
  rate_tier_id NUMBER NOT NULL,
  rate_id NUMBER NOT NULL,
  rate NUMBER(31,10),
  amount_low NUMBER(31,5) NOT NULL,
  amount_high NUMBER(31,5),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  flat_fee NUMBER(31,10),
  rate_code VARCHAR2(50 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;