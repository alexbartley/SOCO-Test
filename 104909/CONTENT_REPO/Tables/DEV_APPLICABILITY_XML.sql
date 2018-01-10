CREATE TABLE content_repo.dev_applicability_xml (
  xml_value CLOB,
  processed_at DATE,
  processing_unit VARCHAR2(100 BYTE) DEFAULT 'taxability.xmlprocess_form'
) 
TABLESPACE content_repo
LOB (xml_value) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);