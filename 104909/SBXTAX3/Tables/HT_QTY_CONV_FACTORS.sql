CREATE TABLE sbxtax3.ht_qty_conv_factors (
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  "FACTOR" NUMBER(31,10),
  from_unit_of_measure_code VARCHAR2(25 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  "OPERATOR" VARCHAR2(10 BYTE),
  qty_conv_factor_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  to_unit_of_measure_code VARCHAR2(25 BYTE),
  aud_qty_conv_factor_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;