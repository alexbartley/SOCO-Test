CREATE TABLE sbxtax.tdr_etl_auth_error_messages (
  nkid NUMBER,
  rid NUMBER,
  severity_id NUMBER NOT NULL,
  severity_description VARCHAR2(200 BYTE) NOT NULL,
  error_msg VARCHAR2(240 BYTE) NOT NULL,
  msg_description VARCHAR2(2000 BYTE) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE
) 
TABLESPACE ositax;