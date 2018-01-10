CREATE TABLE sbxtax3.a_zone_authorities (
  zone_authority_id NUMBER(10),
  zone_id NUMBER(10),
  authority_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  zone_authority_id_o NUMBER(10),
  zone_id_o NUMBER(10),
  authority_id_o NUMBER(10),
  created_by_o NUMBER(10),
  creation_date_o DATE,
  last_updated_by_o NUMBER(10),
  last_update_date_o DATE,
  change_type VARCHAR2(20 BYTE) NOT NULL,
  change_version VARCHAR2(50 BYTE),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;