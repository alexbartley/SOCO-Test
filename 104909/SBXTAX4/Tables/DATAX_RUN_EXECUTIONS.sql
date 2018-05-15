CREATE TABLE sbxtax4.datax_run_executions (
  run_execution_id NUMBER NOT NULL,
  run_id NUMBER NOT NULL,
  data_check_id NUMBER NOT NULL,
  plan_name VARCHAR2(100 BYTE) NOT NULL,
  execution_date DATE NOT NULL,
  execution_plan_id NUMBER
);