CREATE TABLE sbxtax.tb_content_journal (
  content_journal_id NUMBER,
  table_name VARCHAR2(30 CHAR),
  merchant_id NUMBER,
  primary_key NUMBER,
  unique_id_xml VARCHAR2(4000 CHAR),
  operation VARCHAR2(1 CHAR),
  operation_date DATE,
  last_update_date DATE,
  last_updated_by NUMBER,
  created_by NUMBER,
  creation_date DATE
) 
TABLESPACE ositax
LOB (unique_id_xml) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);