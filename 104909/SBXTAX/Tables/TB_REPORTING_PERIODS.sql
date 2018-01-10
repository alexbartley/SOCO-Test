CREATE TABLE sbxtax.tb_reporting_periods (
  reporting_period_id NUMBER NOT NULL,
  reporting_period_set_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  status VARCHAR2(1 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE
) 
TABLESPACE ositax;