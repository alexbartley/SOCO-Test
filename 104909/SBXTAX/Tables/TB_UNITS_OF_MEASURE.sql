CREATE TABLE sbxtax.tb_units_of_measure (
  unit_of_measure_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  code VARCHAR2(25 CHAR) NOT NULL,
  "NAME" VARCHAR2(50 CHAR) NOT NULL,
  base VARCHAR2(25 CHAR) NOT NULL,
  "CATEGORY" VARCHAR2(50 CHAR) NOT NULL,
  description VARCHAR2(200 CHAR),
  rounding_rule VARCHAR2(10 CHAR) NOT NULL,
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