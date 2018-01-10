CREATE TABLE sbxtax4.tmp_tas_inv_desc_c (
  tas_nkid NUMBER,
  authority_uuid VARCHAR2(36 CHAR),
  start_date DATE,
  end_date DATE,
  invoice_description VARCHAR2(250 CHAR),
  extract_id NUMBER,
  nkid NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;