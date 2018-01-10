CREATE TABLE content_repo.taxability_xml_copy_taxes (
  jta_id NUMBER,
  tax_id_old VARCHAR2(100 BYTE),
  reference_code VARCHAR2(20 BYTE),
  jurisdiction_id NUMBER,
  tax_id_new VARCHAR2(100 BYTE)
) 
TABLESPACE content_repo;