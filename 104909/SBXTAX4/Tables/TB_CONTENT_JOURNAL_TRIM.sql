CREATE TABLE sbxtax4.tb_content_journal_trim (
  content_journal_id NUMBER,
  table_name VARCHAR2(30 CHAR),
  merchant_id NUMBER,
  primary_key NUMBER,
  unique_id_xml VARCHAR2(4000 CHAR),
  operation VARCHAR2(1 CHAR),
  operation_date DATE
) 
TABLESPACE ositax
LOB (unique_id_xml) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);