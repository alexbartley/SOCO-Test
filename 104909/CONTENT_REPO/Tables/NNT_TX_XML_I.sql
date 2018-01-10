CREATE TABLE content_repo.nnt_tx_xml_i (
  ent DATE,
  uiusr NUMBER,
  part NUMBER,
  sxi CLOB
) 
TABLESPACE content_repo
LOB (sxi) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW);