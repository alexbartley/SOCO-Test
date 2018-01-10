CREATE TABLE sbxtax2.datax_records (
  record_id NUMBER NOT NULL,
  recorded_message VARCHAR2(1000 BYTE) NOT NULL,
  run_id NUMBER NOT NULL,
  record_date DATE NOT NULL,
  CONSTRAINT datax_records_pk PRIMARY KEY (record_id) USING INDEX 
    TABLESPACE ositax
) 
TABLESPACE ositax;