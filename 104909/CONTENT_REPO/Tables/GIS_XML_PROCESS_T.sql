CREATE TABLE content_repo.gis_xml_process_t (
  process_id NUMBER NOT NULL,
  rid_p NUMBER,
  nkid_p NUMBER,
  "ACTION" NUMBER,
  process_date DATE,
  xmlset CLOB
) 
TABLESPACE content_repo
LOB (xmlset) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW);
COMMENT ON TABLE content_repo.gis_xml_process_t IS 'GIS XML simple log';