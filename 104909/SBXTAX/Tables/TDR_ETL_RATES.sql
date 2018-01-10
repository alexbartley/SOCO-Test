CREATE TABLE sbxtax.tdr_etl_rates (
  nkid NUMBER NOT NULL,
  reference_code VARCHAR2(50 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  tax_structure VARCHAR2(500 CHAR),
  amount_type VARCHAR2(500 CHAR),
  specific_applicability_type VARCHAR2(1000 CHAR) NOT NULL,
  min_threshold NUMBER NOT NULL,
  max_limit NUMBER,
  value_type VARCHAR2(15 CHAR) NOT NULL,
  "VALUE" NUMBER,
  ref_juris_tax_id NUMBER,
  referenced_tax_ref_code VARCHAR2(50 CHAR),
  jurisdiction_nkid NUMBER NOT NULL,
  extract_id NUMBER,
  currency_code VARCHAR2(20 CHAR),
  description VARCHAR2(400 CHAR),
  is_local VARCHAR2(1 CHAR),
  outline_nkid NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;