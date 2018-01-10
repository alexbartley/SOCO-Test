CREATE TABLE sbxtax.tdr_etl_cntr_authorities (
  contributee_uuid VARCHAR2(36 CHAR),
  contributor_uuid VARCHAR2(36 CHAR),
  basis_percent NUMBER,
  start_date DATE,
  end_date DATE,
  nkid NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;