CREATE TABLE sbxtax.tb_merch_auth_period_sets (
  merch_auth_period_set_id NUMBER NOT NULL,
  reporting_period_set_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE
) 
TABLESPACE ositax;