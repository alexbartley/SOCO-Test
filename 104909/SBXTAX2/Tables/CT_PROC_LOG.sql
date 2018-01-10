CREATE TABLE sbxtax2.ct_proc_log (
  log_id NUMBER NOT NULL,
  procedure_name VARCHAR2(100 BYTE) NOT NULL,
  execution_date DATE NOT NULL,
  message VARCHAR2(1000 BYTE) NOT NULL
) 
TABLESPACE ositax;