CREATE TABLE sbxtax2.tb_notification_messages (
  message_id NUMBER(10) NOT NULL,
  channel_id NUMBER(10) NOT NULL,
  message_classification NUMBER(10) NOT NULL,
  "SUMMARY" VARCHAR2(250 BYTE) NOT NULL,
  "CONTENT" VARCHAR2(3500 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;