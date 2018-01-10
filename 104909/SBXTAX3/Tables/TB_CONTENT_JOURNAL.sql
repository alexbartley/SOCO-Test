CREATE TABLE sbxtax3.tb_content_journal (
  content_journal_id NUMBER,
  table_name VARCHAR2(30 BYTE),
  merchant_id NUMBER,
  primary_key NUMBER,
  unique_id_xml VARCHAR2(4000 BYTE),
  operation VARCHAR2(1 BYTE),
  operation_date DATE,
  last_update_date DATE,
  last_updated_by NUMBER,
  created_by NUMBER,
  creation_date DATE
) 
TABLESPACE ositax;