CREATE TABLE sbxtax2.ct_report_exec_history (
  report_id NUMBER NOT NULL,
  status VARCHAR2(100 BYTE) NOT NULL,
  queued_date DATE NOT NULL,
  status_update_date DATE,
  output_filename VARCHAR2(1000 BYTE) NOT NULL,
  exec_parameters VARCHAR2(4000 BYTE) NOT NULL,
  report_exec_id NUMBER NOT NULL
) 
TABLESPACE ositax;