CREATE TABLE content_repo.log_xml_jtx (
  sxmldata XMLTYPE,
  tm DATE,
  rx CLOB
) 
TABLESPACE content_repo
LOB (rx) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW)
LOB (sys_nc00002$) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW);