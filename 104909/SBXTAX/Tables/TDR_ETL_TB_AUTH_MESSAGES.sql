CREATE TABLE sbxtax.tdr_etl_tb_auth_messages (
  authority_uuid VARCHAR2(36 CHAR),
  error_num VARCHAR2(240 CHAR),
  error_severity VARCHAR2(25 CHAR),
  title VARCHAR2(80 CHAR),
  description VARCHAR2(2000 CHAR),
  start_date DATE,
  end_date DATE,
  nkid NUMBER,
  rid NUMBER
) 
TABLESPACE ositax
LOB (description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);