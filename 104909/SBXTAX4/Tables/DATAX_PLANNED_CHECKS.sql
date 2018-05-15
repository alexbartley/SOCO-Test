CREATE TABLE sbxtax4.datax_planned_checks (
  data_check_id NUMBER NOT NULL,
  execution_plan_id NUMBER NOT NULL,
  CONSTRAINT planned_checks_u2 UNIQUE (data_check_id,execution_plan_id)
);