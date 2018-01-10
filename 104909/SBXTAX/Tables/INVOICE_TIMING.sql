CREATE TABLE sbxtax.invoice_timing (
  line_number NUMBER NOT NULL,
  "KEY" NUMBER,
  stop_time VARCHAR2(4000 CHAR),
  start_time NUMBER,
  duration NUMBER,
  concurrent_count NUMBER,
  file_line VARCHAR2(4000 CHAR)
) 
TABLESPACE ositax
LOB (file_line) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (stop_time) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);