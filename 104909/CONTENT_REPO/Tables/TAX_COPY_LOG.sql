CREATE TABLE content_repo.tax_copy_log (
  log_id NUMBER NOT NULL,
  cpy_from_juris_tax_id NUMBER,
  cpy_to_jurisdiction NUMBER,
  cpy_status NUMBER DEFAULT 0,
  cpy_section NUMBER NOT NULL,
  log_date DATE NOT NULL,
  cpy_nkid NUMBER,
  cpy_rid NUMBER,
  juris_imp NUMBER,
  juris_imp_nkid NUMBER,
  juris_imp_rid NUMBER
) 
TABLESPACE content_repo;