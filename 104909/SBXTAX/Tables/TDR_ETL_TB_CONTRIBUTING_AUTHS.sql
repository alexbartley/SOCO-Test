CREATE TABLE sbxtax.tdr_etl_tb_contributing_auths (
  authority_uuid VARCHAR2(36 CHAR),
  this_authority_uuid VARCHAR2(36 CHAR),
  basis_percent NUMBER,
  start_date DATE,
  end_date DATE,
  nkid NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;