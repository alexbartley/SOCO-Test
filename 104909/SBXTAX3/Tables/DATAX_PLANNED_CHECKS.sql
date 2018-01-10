CREATE TABLE sbxtax3.datax_planned_checks (
  data_check_id NUMBER NOT NULL,
  execution_plan_id NUMBER NOT NULL,
  CONSTRAINT planned_checks_u2 UNIQUE (data_check_id,execution_plan_id) USING INDEX 
    TABLESPACE ositax,
  CONSTRAINT datax_planned_checks_plan_fk FOREIGN KEY (execution_plan_id) REFERENCES sbxtax3.datax_execution_plans (execution_plan_id),
  CONSTRAINT datax_run_plans_fk FOREIGN KEY (data_check_id) REFERENCES sbxtax3.datax_checks (data_check_id)
) 
TABLESPACE ositax;