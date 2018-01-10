CREATE TABLE content_repo.tmp_crapp_30564_corrections (
  rule_id NUMBER,
  authority_name VARCHAR2(200 BYTE),
  product_name VARCHAR2(200 BYTE),
  juris_tax_applicability_nkid VARCHAR2(200 BYTE),
  tax_appl_nkid VARCHAR2(200 BYTE),
  rule_order NUMBER,
  tr_start_date VARCHAR2(200 BYTE),
  tdr_start_date VARCHAR2(200 BYTE),
  tr_end_date VARCHAR2(200 BYTE),
  commodity_start_date VARCHAR2(200 BYTE),
  tax_type VARCHAR2(200 BYTE),
  tax_research_comment VARCHAR2(2000 BYTE)
) 
TABLESPACE content_repo;