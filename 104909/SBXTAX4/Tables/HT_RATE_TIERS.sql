CREATE TABLE sbxtax4.ht_rate_tiers (
  amount_high NUMBER(31,5),
  amount_low NUMBER(31,5),
  created_by NUMBER(10),
  creation_date DATE,
  flat_fee NUMBER(31,10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  rate NUMBER(31,10),
  rate_code VARCHAR2(50 BYTE),
  rate_id NUMBER(10),
  rate_tier_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_rate_tier_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;