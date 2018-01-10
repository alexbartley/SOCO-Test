CREATE TABLE sbxtax.pvw_tb_contributing_auths (
  authority_uuid VARCHAR2(144 CHAR),
  basis_percent NUMBER,
  end_date DATE,
  start_date DATE,
  this_authority_uuid VARCHAR2(144 CHAR),
  authority_id NUMBER,
  this_authority_id NUMBER,
  contributing_authority_id NUMBER
) 
TABLESPACE ositax;