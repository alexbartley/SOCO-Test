CREATE TABLE sbxtax4.etl_proc_log (
  "ID" NUMBER NOT NULL,
  "ACTION" VARCHAR2(256 CHAR),
  message VARCHAR2(1000 CHAR) NOT NULL,
  entity VARCHAR2(100 CHAR),
  nkid NUMBER,
  rid NUMBER,
  log_time TIMESTAMP NOT NULL
) 
TABLESPACE ositax;