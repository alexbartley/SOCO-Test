CREATE TABLE sbxtax4.tb_currencies (
  currency_id NUMBER NOT NULL,
  currency_code VARCHAR2(3 CHAR) NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  description VARCHAR2(200 CHAR),
  rounding_rule VARCHAR2(10 CHAR) NOT NULL,
  rounding_precision NUMBER(31,5) NOT NULL,
  min_accountable_unit NUMBER(31,5),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;