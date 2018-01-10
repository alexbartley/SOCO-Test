CREATE TABLE sbxtax3.tb_units_of_measure (
  unit_of_measure_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  code VARCHAR2(25 BYTE) NOT NULL,
  "NAME" VARCHAR2(50 BYTE) NOT NULL,
  base VARCHAR2(25 BYTE) NOT NULL,
  "CATEGORY" VARCHAR2(50 BYTE) NOT NULL,
  description VARCHAR2(200 BYTE),
  rounding_rule VARCHAR2(10 BYTE) NOT NULL,
  rounding_precision NUMBER(31,5) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;