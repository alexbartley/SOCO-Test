CREATE TABLE content_repo.errlog (
  errcode NUMBER(*,0) NOT NULL,
  errmsg VARCHAR2(4000 CHAR) NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  entered_by NUMBER NOT NULL,
  stacktrace VARCHAR2(4000 CHAR)
) 
TABLESPACE content_repo
LOB (errmsg) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (stacktrace) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);