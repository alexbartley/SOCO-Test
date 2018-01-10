CREATE TABLE sbxtax.tb_notification_messages (
  message_id NUMBER NOT NULL,
  channel_id NUMBER NOT NULL,
  message_classification NUMBER(10) NOT NULL,
  "SUMMARY" VARCHAR2(250 CHAR) NOT NULL,
  "CONTENT" VARCHAR2(3500 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax
LOB ("CONTENT") STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);