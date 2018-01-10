CREATE TABLE sbxtax3.a_change_record (
  "ID" NUMBER NOT NULL,
  content_type VARCHAR2(20 BYTE) NOT NULL,
  content_version VARCHAR2(1000 BYTE) NOT NULL,
  xml_clob CLOB NOT NULL,
  description VARCHAR2(500 BYTE),
  consumer VARCHAR2(100 BYTE),
  file_ext VARCHAR2(4 BYTE),
  creation_date TIMESTAMP,
  last_update_date TIMESTAMP
) 
TABLESPACE ositax
LOB (xml_clob) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW);