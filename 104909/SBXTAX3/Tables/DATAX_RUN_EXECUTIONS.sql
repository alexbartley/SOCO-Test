CREATE TABLE sbxtax3.datax_run_executions (
  run_execution_id NUMBER NOT NULL,
  run_id NUMBER NOT NULL,
  data_check_id NUMBER NOT NULL,
  plan_name VARCHAR2(100 BYTE) NOT NULL,
  execution_date DATE NOT NULL,
  execution_plan_id NUMBER,
  CONSTRAINT datax_run_exec_data_check_fk FOREIGN KEY (data_check_id) REFERENCES sbxtax3.datax_checks (data_check_id)
) 
TABLESPACE ositax;