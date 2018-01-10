CREATE TABLE sbxtax.tdr_etl_jta_inv_desc (
  authority_uuid VARCHAR2(36 CHAR),
  start_date DATE,
  end_date DATE,
  invoice_description VARCHAR2(250 CHAR),
  extract_id NUMBER,
  nkid NUMBER,
  rid NUMBER,
  tat_id NUMBER
) 
TABLESPACE ositax;