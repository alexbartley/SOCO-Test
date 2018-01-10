CREATE TABLE sbxtax4.data_check_err_log (
  datacheckid NUMBER NOT NULL,
  runid NUMBER,
  errcode NUMBER NOT NULL,
  errmsg VARCHAR2(4000 CHAR) NOT NULL,
  step_number VARCHAR2(100 CHAR),
  entered_date DATE DEFAULT SYSDATE NOT NULL,
  entered_by NUMBER NOT NULL
) 
TABLESPACE ositax
LOB (errmsg) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);