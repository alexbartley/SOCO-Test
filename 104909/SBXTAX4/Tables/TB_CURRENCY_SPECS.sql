CREATE TABLE sbxtax4.tb_currency_specs (
  currency_spec_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  currency_id NUMBER NOT NULL,
  is_default VARCHAR2(1 CHAR),
  exchange_rate_source_id NUMBER NOT NULL,
  rounding_rule VARCHAR2(10 CHAR) NOT NULL,
  rounding_precision NUMBER(31,5) NOT NULL,
  min_accountable_unit NUMBER(31,5),
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;