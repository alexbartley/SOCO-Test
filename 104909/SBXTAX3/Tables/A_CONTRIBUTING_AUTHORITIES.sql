CREATE TABLE sbxtax3.a_contributing_authorities (
  contributing_authority_id NUMBER(10),
  merchant_id NUMBER(10),
  authority_id NUMBER(10),
  this_authority_id NUMBER(10),
  basis_percent NUMBER(31,10),
  start_date DATE,
  end_date DATE,
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  contributing_authority_id_o NUMBER(10),
  merchant_id_o NUMBER(10),
  authority_id_o NUMBER(10),
  this_authority_id_o NUMBER(10),
  basis_percent_o NUMBER(31,10),
  start_date_o DATE,
  end_date_o DATE,
  created_by_o NUMBER(10),
  creation_date_o DATE,
  last_updated_by_o NUMBER(10),
  last_update_date_o DATE,
  change_type VARCHAR2(20 BYTE) NOT NULL,
  change_version VARCHAR2(50 BYTE),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;