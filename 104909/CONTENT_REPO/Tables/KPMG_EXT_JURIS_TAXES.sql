CREATE TABLE content_repo.kpmg_ext_juris_taxes (
  juris_tax_id NUMBER,
  jurisdiction_name VARCHAR2(250 CHAR),
  taxation_type VARCHAR2(100 CHAR),
  reference_code VARCHAR2(50 CHAR),
  transaction_type VARCHAR2(100 CHAR),
  spec_applicabiliity_type VARCHAR2(100 CHAR),
  revenue_purpose_description VARCHAR2(50 CHAR),
  tax_structure VARCHAR2(500 CHAR),
  tax_value_type VARCHAR2(15 CHAR),
  referenced_code VARCHAR2(50 CHAR),
  tax_value NUMBER,
  min_threshold NUMBER,
  max_limit NUMBER,
  start_date VARCHAR2(10 CHAR),
  end_date VARCHAR2(10 CHAR),
  out_rid NUMBER
) 
TABLESPACE content_repo;