CREATE TABLE sbxtax3.datax_execution_plans (
  plan_name VARCHAR2(100 BYTE) NOT NULL,
  execution_plan_id NUMBER NOT NULL,
  param_1_name VARCHAR2(100 BYTE),
  param_1_value VARCHAR2(100 BYTE),
  CONSTRAINT datax_execution_plan_pk PRIMARY KEY (execution_plan_id) USING INDEX 
    TABLESPACE ositax
) 
TABLESPACE ositax;