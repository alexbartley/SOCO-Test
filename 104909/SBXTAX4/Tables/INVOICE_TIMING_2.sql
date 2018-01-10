CREATE TABLE sbxtax4.invoice_timing_2 (
  line_number NUMBER,
  "KEY" NUMBER,
  stop_time NUMBER,
  start_time NUMBER,
  duration NUMBER,
  concurrent_count NUMBER,
  file_line VARCHAR2(4000 CHAR)
) 
TABLESPACE ositax
LOB (file_line) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);