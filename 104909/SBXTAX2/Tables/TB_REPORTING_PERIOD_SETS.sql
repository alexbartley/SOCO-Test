CREATE TABLE sbxtax2.tb_reporting_period_sets (
  reporting_period_set_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  period_set_type VARCHAR2(20 BYTE),
  num_days NUMBER,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE
) 
TABLESPACE ositax;