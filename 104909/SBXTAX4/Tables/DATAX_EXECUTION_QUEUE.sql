CREATE TABLE sbxtax4.datax_execution_queue (
  execution_queue_id NUMBER NOT NULL,
  execution_plan_id NUMBER NOT NULL,
  status VARCHAR2(100 BYTE) NOT NULL,
  queued_date DATE NOT NULL,
  status_update_date DATE NOT NULL
) 
TABLESPACE ositax;