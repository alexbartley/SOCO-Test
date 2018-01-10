CREATE TABLE sbxtax3.tb_qty_conv_factors (
  qty_conv_factor_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  from_unit_of_measure_code VARCHAR2(25 BYTE) NOT NULL,
  to_unit_of_measure_code VARCHAR2(25 BYTE) NOT NULL,
  "FACTOR" NUMBER(31,10) NOT NULL,
  "OPERATOR" VARCHAR2(10 BYTE) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;